//
//  ClipboardMonitor.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/17/24.
//

import QuickLookThumbnailing
import SwiftUI
import Combine
import Cocoa
import CoreData
import AppKit
import CryptoKit

class ClipboardMonitor: ObservableObject {
    let userDefaultsManager = UserDefaultsManager.shared
    
    private var checkTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    private var maxItemCount: Int    
    
    @Published var tmpFolderPath = FileManager.default.temporaryDirectory
    
    init() {
        self.maxItemCount = userDefaultsManager.maxStoreCount * 2
    }
                
    func startMonitoring() {
        checkTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkClipboard), userInfo: nil, repeats: true)
    }
    
    @objc private func checkClipboard() {
        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            if pasteboard.changeCount != self.lastChangeCount {
                self.lastChangeCount = pasteboard.changeCount
                self.processDataFromClipboard()
            }
        }
    }
    
    private func processDataFromClipboard() {
        
        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            
            // making a child context because I need to be able to create Items for the group and checkLast before saving,
            // parent context is available to the content view even without saving, so I need them seperate
            let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//            let context = PersistenceController.shared.container.viewContext
            childContext.parent = PersistenceController.shared.container.viewContext

            childContext.perform {
                if let items = pasteboard.pasteboardItems, !items.isEmpty {
                    let group = ClipboardGroup(context: childContext)
                    group.timeStamp = Date()
                    group.count = Int16(min(items.count, self.userDefaultsManager.maxStoreCount))
                    
                    var operationsPending = 0
                    var counter = 0
                    for item in items {
                        if counter >= self.maxItemCount {
                            continue
                        }
                        // Check for file URLs first
                        if let urlString = item.string(forType: .fileURL), let fileUrl = URL(string: urlString) {
                            if self.userDefaultsManager.canCopyImages || self.userDefaultsManager.canCopyFilesOrFolders {
                                operationsPending += 1
                                self.processFileFolder(fileUrl: fileUrl, inGroup: group, context: childContext) { completion in
                                    defer {
                                        operationsPending -= 1
                                        if operationsPending == 0 {
                                            self.saveClipboardGroup(childContext: childContext)
                                        }
                                    }
                                    if !completion {
                                        print("Failed to process file at URL: \(fileUrl)")
                                    }
                                }
                            }
                        }
                        else if let imageData = pasteboard.data(forType: .tiff), let image = NSImage(data: imageData) {
                            if self.userDefaultsManager.canCopyImages {
                                self.processImageData(image: image, inGroup: group, context: childContext)
                            }
                        }
                        else if let content = pasteboard.string(forType: .string) {
                            let item = ClipboardItem(context: childContext)
                            item.content = content
                            item.type = "text"
                            item.filePath = nil
                            item.imageData = nil
                            item.imageHash = nil
                            item.group = group
                            group.addToItems(item)
                        }
                        counter += 1
                    }
                    if operationsPending == 0 {
                        self.saveClipboardGroup(childContext: childContext)
                    }
                }
            }
        }
    }
    
    private func processFileFolder(fileUrl: URL, inGroup group: ClipboardGroup, context: NSManagedObjectContext,
                                   completion: @escaping (Bool) -> Void) {
        let acceptableFileTypes = [
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key",
            "txt", "rtf", "odt", "md", "csv",
            "jpeg", "jpg", "png", "gif", "tiff", "tif", "bmp", "heic", "svg", "webp",
            "mp3", "aac", "wav", "aiff", "flac", "m4a",
            "mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv", "webm",
            "html", "htm", "css", "xml", "json", "plist"
        ]
        let imageExtensions = ["tiff", "jpeg", "jpg", "png", "svg", "gif", "icns"]
        let zipExtensions = ["zip", "tar", "tar.gz", "tgz", "tar.bz2", "tbz2", "7z", "rar"]
        let dmgExtension = "dmg"

        let fileExtension = fileUrl.pathExtension.lowercased()
        
        context.perform {
            let item = ClipboardItem(context: context)
            item.content = fileUrl.lastPathComponent
            item.filePath = fileUrl.path
            item.group = group
            
            if self.userDefaultsManager.canCopyImages && imageExtensions.contains(fileExtension) {
                if let image = NSImage(contentsOf: fileUrl) {
                    if let tiffRep = image.tiffRepresentation {
                        let imageHash = self.hashImageData(tiffRep)
                        item.type = "image"
                        item.imageData = image.tiffRepresentation
                        item.imageHash = imageHash
                        group.addToItems(item)
                        completion(true)
                        return
                    }
                }
                completion(false)
            }
            else if self.userDefaultsManager.canCopyFilesOrFolders {
                do {
                    item.imageData = nil
                    item.imageHash = nil
                    
                    let resourceValues = try fileUrl.resourceValues(forKeys: [.isDirectoryKey, /*.isSymbolicLinkKey,*/ .isAliasFileKey, .isUbiquitousItemKey, .volumeIsRemovableKey, .isExecutableKey])
                    
                    if let isDirectory = resourceValues.isDirectory, isDirectory ||  fileUrl.path == "/Applications/Safari.app" {
                        if let volumeIsRemovable = resourceValues.volumeIsRemovable, volumeIsRemovable {
                            item.type = "removable"
                            print("removable")
                        }
                        else if fileExtension == "app" {
                            if let appIcon = self.extractAppIcon(for: fileUrl), let appIconImageData = appIcon.tiffRepresentation {
                                item.type = "app"
                                item.imageData = appIconImageData
                            }
                            else if item.content == "Calendar.app" {
                                item.type = "calendarApp"
                            }
                            else if item.content == "Photo Booth.app" {
                                item.type = "photoBoothApp"
                            }
                            else if item.content == "System Settings.app" {
                                item.type = "settingsApp"
                            }
                        }
                        else {
                            item.type = "folder"
                        }
                        group.addToItems(item)
                        completion(true)
                    }
//                    else if let isSymbolicLink = resourceValues.isSymbolicLink, isSymbolicLink {
//                        // haven't tested these
//                        item.type = "symlink"
//                        group.addToItems(item)
//                        completion(true)
//                    }
                    else if let isAliasFile = resourceValues.isAliasFile, isAliasFile {
                        item.type = "alias"
                        // here is where I check for the alias's actual file/folder and deteminie if it is a file, folder, image or something else
                        if let resolvedUrl = self.resolveAlias(fileUrl: fileUrl) {
                            let resolvedResourceValues = try resolvedUrl.resourceValues(forKeys: [.isDirectoryKey, .contentTypeKey])
                            
                            if let isDirectory = resolvedResourceValues.isDirectory, isDirectory {
                                // It's a directory/folder, do nothing because the alias image is set as the folder icon
                            }
                            else {
                                if let contentType = resolvedResourceValues.contentType {
                                    if contentType.conforms(to: .image) {
                                        if let image = NSImage(contentsOf: resolvedUrl) {
                                            item.imageData = image.tiffRepresentation
                                        }
                                    } else {
                                        self.generateThumbnail(for: resolvedUrl.path) { thumbnail in
                                            item.imageData = thumbnail?.tiffRepresentation
                                        }
                                    }
                                }
                            }
                        }
                        group.addToItems(item)
                        completion(true)
                    }
                    else if let isExecutable = resourceValues.isExecutable, isExecutable {
                        item.type = "execFile"
                        item.imageData = nil
                        item.imageHash = nil
                        group.addToItems(item)
                        completion(true)
                    }
                    else {
                        // regular file                        
                        if zipExtensions.contains(fileExtension) {
                            item.type = "zipFile"
                            item.imageData = nil
                            item.imageHash = nil
                            group.addToItems(item)
                            completion(true)
                        }
                        else if fileExtension == dmgExtension {
                            item.type = "dmgFile"
                            item.imageData = nil
                            item.imageHash = nil
                            group.addToItems(item)
                            completion(true)
                        }
                        else if acceptableFileTypes.contains(fileExtension) {
                            self.generateThumbnail(for: fileUrl.path) { thumbnail in
                                if let thumbnail = thumbnail {
                                    item.type = "file"
                                    item.imageData = thumbnail.tiffRepresentation
                                    item.imageHash = nil
                                    group.addToItems(item)
                                    completion(true)
                                }
                                else {
                                    // thumbnail failed, not a typical file
                                    item.type = "randomFile"
                                    item.imageData = nil
                                    item.imageHash = nil
                                    group.addToItems(item)
                                    completion(true)
                                }
                            }
                        }
                        else {
                            item.type = "randomFile"
                            item.imageData = nil
                            item.imageHash = nil
                            group.addToItems(item)
                            completion(true)
                        }
                    }
                }
                catch {
                    print("Error checking file type: \(error)")
                    completion(false)
                }
            }
            //        group.addToItems(item)
        }
    }
    
    // determine file path that alias points to
    func resolveAlias(fileUrl: URL) -> URL? {
        do {
            let resourceValues = try fileUrl.resourceValues(forKeys: [.isAliasFileKey])
            if resourceValues.isAliasFile == true {
                let originalUrl = try URL(resolvingAliasFileAt: fileUrl, options: [])
                return originalUrl
            }
        } catch {
            print("Failed to resolve alias: \(error)")
        }
        return nil
    }
    
    // takes in imageData, like a screenshot, turns it into an image file
    // image file is stored as a temp file, user can copy and paste anywhere, but temp file is deleted when clipboard item is eventually deleted
    private func processImageData(image: NSImage, inGroup group: ClipboardGroup, context: NSManagedObjectContext) {
        if let imageData = image.tiffRepresentation {
            // this is called when I take the screenshot in the first place
            let imageHash = self.hashImageData(imageData)
            
            if let imageFileURL = createImageFile(imageData: imageData) {
                let item = ClipboardItem(context: context)
                item.content = imageFileURL.lastPathComponent
                item.filePath = imageFileURL.path
                item.type = "image"
                item.imageData = image.tiffRepresentation
                item.imageHash = imageHash
                item.group = group
                group.addToItems(item)
                
//                saveClipboard(content: imageFileURL.lastPathComponent, type: "image", imageData: image.tiffRepresentation, filePath: imageFileURL.path, imageHash: imageHash)
                
                let url = URL(fileURLWithPath: imageFileURL.path)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([url as NSURL])
            }
        }
    }
    
    func findItems(content: String?, type: String?, imageHash: String?, filePath: String?, context: NSManagedObjectContext?) -> [ClipboardItem] {
        let context = context ?? PersistenceController.shared.container.viewContext
        var results: [ClipboardItem] = []
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
            
            var predicates: [NSPredicate] = []
            
            if let content = content {
                predicates.append(NSPredicate(format: "content == %@", content))
            }
            if let type = type {
                predicates.append(NSPredicate(format: "type == %@", type))
            }
            if let imageHash = imageHash {
                predicates.append(NSPredicate(format: "imageHash == %@", imageHash))
            }
            if let filePath = filePath {
                predicates.append(NSPredicate(format: "filePath == %@", filePath))
            }
            
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            
            fetchRequest.fetchLimit = self.maxItemCount
            
            do {
                results = try context.fetch(fetchRequest)
            } catch {
                print("Fetch failed: \(error.localizedDescription)")
            }
        }
        return results
    }
    
    private func saveClipboardGroup(childContext: NSManagedObjectContext) {
        childContext.perform {
            if !self.checkLast(childContext: childContext) {
                return
            }
            
            let fetchRequest: NSFetchRequest<ClipboardGroup> = ClipboardGroup.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
            
            do {
                var groups = try childContext.fetch(fetchRequest)
                
                if let group = groups.first, self.userDefaultsManager.noDuplicates {
                    self.cleanUpDuplicates(for: group, childContext: childContext)
                }

                self.cleanUpExtraItems(childContext: childContext, inputGroups: groups)
                
                var groupCount = groups.count
                
                while groupCount > self.userDefaultsManager.maxStoreCount {
                    if let oldestGroup = groups.last {
                        self.deleteGroupAndItems(oldestGroup, childContext: childContext)
                        groupCount -= 1
                        groups.removeLast()
                    }
                }
                
                try childContext.save()
                //            try childContext.parent?.save()
                if let parentContext = childContext.parent {
                    parentContext.performAndWait {
                        do {
                            try parentContext.save()
                        } catch {
                            print("Failed to save parent context: \(error)")
                        }
                    }
                }
                
                return
            } catch {
                print("Failed to save and update groups: \(error)")
                return
            }
        }
    }

    func checkLast(childContext: NSManagedObjectContext) -> Bool {
        var shouldSave = false
        
        
        childContext.performAndWait {
            let fetchRequest: NSFetchRequest<ClipboardGroup> = ClipboardGroup.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
            fetchRequest.fetchLimit = 2 // 2 because new item and last item
            
            do {
                let results = try childContext.fetch(fetchRequest)
                
                if results.count < 2 { // less than 2 means there wasnt anything copied before, so save it
                    shouldSave = true
                }
                else if let newGroup = results.last, let lastGroup = results.dropLast().last {
                    let lastItems = lastGroup.itemsArray
                    let newItems = newGroup.itemsArray
                    
                    if lastItems.count != newItems.count {
                        // Different number of items, definitely save
                        shouldSave = true
                    } else {
                        // Compare the sorted arrays item by item
                        shouldSave = !zip(lastItems, newItems).allSatisfy { ClipboardItem.isEqual(itemA: $0, itemB: $1) }
                    }
                }
            } catch {
                print("Fetch failed: \(error.localizedDescription)")
                shouldSave = false
            }
        }
        return shouldSave
    }
    
    func checkLast(group: ClipboardGroup?, item: ClipboardItem?, context: NSManagedObjectContext?) -> Bool {
        if (group == nil && item == nil) || (group != nil && item != nil) {
            return false
        }
        
        var shouldSave = false
                
        let context = context ?? PersistenceController.shared.container.viewContext
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<ClipboardGroup> = ClipboardGroup.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
            fetchRequest.fetchLimit = 2
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.first == nil {
                    // blank list
                    shouldSave = true
                }
                
                else if let lastGroup = results.first {
                    let lastItems = lastGroup.itemsArray
                    if let group = group {
                        let newItems = group.itemsArray
                        if lastItems.count != newItems.count {
                            // Different number of items, definitely save
                            shouldSave = true
                        }
                        else {
                            // Compare the sorted arrays item by item
                            shouldSave = !zip(lastItems, newItems).allSatisfy { ClipboardItem.isEqual(itemA: $0, itemB: $1) }
                        }
                    }
                    else if let item = item {
                        if lastItems.count != 1 {
                            // last group is not a single item, so they arent the same
                            shouldSave = true
                        }
                        else if let lastItem = lastItems.first {
                            // Compare the items
                            shouldSave = !ClipboardItem.isEqual(itemA: item, itemB: lastItem)
                        }
                    }
                }
            } catch {
                print("Fetch failed: \(error.localizedDescription)")
                shouldSave = false
            }
        }
        return shouldSave
    }
    
    func cleanUpDuplicates(for group: ClipboardGroup, childContext: NSManagedObjectContext) {
        
        childContext.performAndWait {
            let fetchRequest: NSFetchRequest<ClipboardGroup> = ClipboardGroup.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
            fetchRequest.fetchLimit = self.userDefaultsManager.maxStoreCount
            
            do {
                let results = try childContext.fetch(fetchRequest)
                
                if results.count < 2 { // less than 2 means there wasnt anything copied before, so save it
                    return
                }
                else {
                    
                    let foundDupe = results.contains(where: { $0 != results.first && ClipboardGroup.isDupe(groupA: group, groupB: $0) })
                    
                    if foundDupe && results.count > 1 {
                        for result in results where  result != results.first {
                            if ClipboardGroup.isDupe(groupA: group, groupB: result) {
                                childContext.delete(result)
                            }
                        }
                    }
                }
                
            } catch {
                print("Fetch failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func cleanUpExtraItems(childContext: NSManagedObjectContext, inputGroups: [ClipboardGroup]?) {
        childContext.performAndWait {
            var groups: [ClipboardGroup]
            
            if let existingGroups = inputGroups {
                groups = existingGroups
            } else {
                let fetchRequest: NSFetchRequest<ClipboardGroup> = ClipboardGroup.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
                do {
                    groups = try childContext.fetch(fetchRequest)
                } catch {
                    print("Failed to fetch groups for cleanup: \(error.localizedDescription)")
                    return
                }
            }
            
            if groups.count == 1, let group = groups.first, let item = group.itemsArray.first, item.type != "image" {
                // only clears on first copy when list is blank, if first copy isnt an image
                self.clearTmpImages()
            }
            
            //        do {
            var totalItems = groups.reduce(0) { $0 + ($1.items?.count ?? 0) }
            
            while totalItems > self.maxItemCount {
                if let oldestGroup = groups.last {
                    let itemCount = oldestGroup.items?.count ?? 0
                    self.deleteGroupAndItems(oldestGroup, childContext: childContext)
                    groups.removeLast()
                    totalItems -= itemCount
                }
            }
            //            try childContext.save()
            //        } catch {
            //            print("Failed to clean up groups: \(error.localizedDescription)")
            //        }
        }
    }
    
    func deleteGroupAndItems(_ group: ClipboardGroup, childContext: NSManagedObjectContext) {
        childContext.performAndWait {
            if let items = group.items as? Set<ClipboardItem> {
                for item in items {
                    self.deleteItem(item, childContext: childContext)
                }
            }
            childContext.delete(group)
        }
    }
    
    func deleteItem(_ item: ClipboardItem, childContext: NSManagedObjectContext) {
        childContext.performAndWait {
            let folderPath = self.tmpFolderPath
            if let filePath = item.filePath, filePath.contains(folderPath.path) {
                // if the file is not still in the clipboard history
                let items = self.findItems(content: nil, type: nil, imageHash: item.imageHash, filePath: filePath, context: childContext)
                
                // only want to delete file if its the only copy left
                if items.count < 2 {
                    self.deleteTmpImage(filePath: filePath)
                }
            }
            childContext.delete(item)
        }
    }
    
    private func generateThumbnail(for filePath: String?, completion: @escaping (NSImage?) -> Void) {
        guard let filePath = filePath else {
            completion(nil)
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let size = CGSize(width: 100, height: 100)
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: size, scale: scale, representationTypes: .thumbnail)
        
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { (thumbnail, _, error) in
            if let error = error {
                print("Thumbnail generation failed: \(error)")
                completion(nil)
            } else if let thumbnail = thumbnail {
                let nsImage = NSImage(cgImage: thumbnail.cgImage, size: size)
                completion(nsImage)
            } else {
                completion(nil)
            }
        }
    }
        
    private func createImageFile(imageData: Data?) -> URL? {
        guard let image = NSImage(data: imageData!) else {
            print("Failed to create image from TIFF data.")
            return nil
        }

        if let pngData = convertNSImageToPNG(image: image) {
            let formatter = DateFormatter()
            // format of: 2024-08-05 at 12.39.38 PM
            formatter.dateFormat = "yyyy-MM-dd h.mm.ss bb"
            let fileDate = formatter.string(from: Date())
            let splitDate = fileDate.split(separator: " ")
            let filePathDate = splitDate[0] + " at " + splitDate[1]
            
            if let imageFileURL = saveImageDataToFile(imageData: pngData, filePath: "Image \(filePathDate)", fileType: .png) {
                return imageFileURL
            }
            else { return nil }
        } else {
            print("Failed to convert image to JPEG.")
            return nil
        }
    }

    private func convertNSImageToPNG(image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    private func saveImageDataToFile(imageData: Data, filePath: String, fileType: NSBitmapImageRep.FileType) -> URL? {
        let folderPath: URL
        do {
//            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//            folderPath = documentsURL  // Change this to .downloadsDirectory if preferred
            folderPath = tmpFolderPath

            let fileURL = folderPath.appendingPathComponent(filePath + (fileType == .jpeg ? ".jpg" : ".png"))
                        
            try imageData.write(to: fileURL, options: .atomic)
            
            print("File saved: \(fileURL.path)")
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
        
    }
    
    func deleteTmpImage(filePath: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: filePath)
            
            print("File deleted: \(filePath)")
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    func clearTmpImages() {
        let fileManager = FileManager.default
        let folderPath = tmpFolderPath
        
        do {
            let items = try fileManager.contentsOfDirectory(atPath: folderPath.path)
            for item in items {
                let itemURL = URL(fileURLWithPath: item, relativeTo: fileManager.temporaryDirectory)
                if itemURL.pathExtension == "png" {
                    try fileManager.removeItem(at: itemURL)
                }
            }
        } catch let error {
            print("Failed to clear .png files from temp directory: \(error)")
        }
    }
    
    // creates a comparaple hash to quickly compare images
    private func hashImageData(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func extractAppIcon(for fileUrl: URL) -> NSImage? {
        let contentsUrl = fileUrl.appendingPathComponent("Contents")
        let plistUrl = contentsUrl.appendingPathComponent("Info.plist")
        
        guard let plist = NSDictionary(contentsOf: plistUrl),
              let iconName = plist["CFBundleIconFile"] as? String else {
            return nil
        }

        let iconExtension = (iconName as NSString).pathExtension.isEmpty ? "icns" : (iconName as NSString).pathExtension
        let iconFileName = (iconName as NSString).deletingPathExtension
        let appResourcesIconUrl = contentsUrl.appendingPathComponent("Resources").appendingPathComponent(iconFileName).appendingPathExtension(iconExtension)

        return NSImage(contentsOf: appResourcesIconUrl)
        
//        // find appIcon in its resources folder
//        if let appIcon = NSImage(contentsOf: appResourcesIconUrl) {
//            return appIcon
//        }
//        
//        // if icon isn't found, check the system resources (typically default apps might store icon here)
//        let systemResourcesUrl = URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/")
//        let systemIconUrl = systemResourcesUrl.appendingPathComponent(iconFileName).appendingPathExtension(iconExtension)
//
//        return NSImage(contentsOf: systemIconUrl)
    }
    
    deinit {
        checkTimer?.invalidate()
    }
}

