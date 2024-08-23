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
    private var checkTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    private var maxItemCount: Int = 50
    
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
            
//            let imageExtensions = ["tiff", "jpeg", "jpg", "png", "svg", "gif"]
            
            if let items = pasteboard.pasteboardItems, !items.isEmpty {
//                var group = ClipboardGroup()
                
                for item in items {
                    
                    // Check for file URLs first
                    if let urlString = item.string(forType: .fileURL), let fileUrl = URL(string: urlString) {
                        self.processFileFolder(fileUrl: fileUrl)
                    }
                    else if let imageData = pasteboard.data(forType: .tiff), let image = NSImage(data: imageData) {
                        self.processImageData(image: image)
                    }
                    else if let content = pasteboard.string(forType: .string) {
                        self.saveClipboard(content: content, type: "text", imageData: nil, filePath: nil, imageHash: nil)
                    }
                }

            }
        }
    }
    
    private func processFileFolder(fileUrl: URL) {
        let imageExtensions = ["tiff", "jpeg", "jpg", "png", "svg", "gif"]

        let fileExtension = fileUrl.pathExtension.lowercased()
        
        if imageExtensions.contains(fileExtension) {
            if let image = NSImage(contentsOf: fileUrl) {
                if let tiffRep = image.tiffRepresentation {
                    let imageHash = self.hashImageData(tiffRep)
                    self.saveClipboard(content: fileUrl.lastPathComponent, type: "image", imageData: image.tiffRepresentation, filePath: fileUrl.path, imageHash: imageHash)
                }
            }
        } else {
            do {
                let resourceValues = try fileUrl.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isAliasFileKey, .isUbiquitousItemKey, .volumeIsRemovableKey])
                
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    self.saveClipboard(content: fileUrl.lastPathComponent, type: "folder", imageData: nil, filePath: fileUrl.path, imageHash: nil)
                } else if let isSymbolicLink = resourceValues.isSymbolicLink, isSymbolicLink {
                    self.saveClipboard(content: fileUrl.lastPathComponent, type: "symlink", imageData: nil, filePath: fileUrl.path, imageHash: nil)
                } else if let isAliasFile = resourceValues.isAliasFile, isAliasFile {
                    self.saveClipboard(content: fileUrl.lastPathComponent, type: "alias", imageData: nil, filePath: fileUrl.path, imageHash: nil)
                } else if let volumeIsRemovable = resourceValues.volumeIsRemovable, volumeIsRemovable {
                    self.saveClipboard(content: fileUrl.lastPathComponent, type: "removable", imageData: nil, filePath: fileUrl.path, imageHash: nil)
                } else {
                    
                    self.generateThumbnail(for: fileUrl.path) { thumbnail in
                        self.saveClipboard(content: fileUrl.lastPathComponent, type: "file", imageData: thumbnail?.tiffRepresentation, filePath: fileUrl.path, imageHash: nil)
                    }
                }
            } catch {
                print("Error checking file type: \(error)")
            }
        }
    }
    // takes in imageData, like a screenshot, turns it into an image file
    // image file is stored as a temp file, user can copy and paste anywhere, but temp file is deleted when clipboard item is eventually deleted
    private func processImageData(image: NSImage) {
        if let imageData = image.tiffRepresentation {
            // this is called when I take the screenshot in the first place
            let imageHash = self.hashImageData(imageData)
            
            if let imageFileURL = createImageFile(imageData: imageData) {
                saveClipboard(content: imageFileURL.lastPathComponent, type: "image", imageData: image.tiffRepresentation, filePath: imageFileURL.path, imageHash: imageHash)
                let url = URL(fileURLWithPath: imageFileURL.path)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([url as NSURL])
            }
        }
    }
    
    func findItems(content: String?, type: String?, imageHash: String?, filePath: String?) -> [ClipboardItem] {
        let context = PersistenceController.shared.container.viewContext
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
        
        fetchRequest.fetchLimit = maxItemCount

        do {
            let results = try context.fetch(fetchRequest)
            return results
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private func saveClipboard(content: String?, type: String, imageData: Data?, filePath: String?, imageHash: String?, completion: ((Bool) -> Void)? = nil) {
        if !checkLast(item: nil, content: content, type: type, imageData: imageData, filePath: filePath, imageHash: imageHash) {
            completion?(false)
            return
        }
            
        DispatchQueue.main.async {
            
            let context = PersistenceController.shared.container.viewContext
            
            context.perform {
                let formatter = DateFormatter()
                // 2024-08-05 at 12.39.38 PM
                formatter.dateFormat = "yyyy-MM-dd h.mm.ss bb"
                
                let newClipboardItem = ClipboardItem(context: context)
                newClipboardItem.content = content
                newClipboardItem.timeStamp = formatter.date(from: formatter.string(from: Date()))
//                newClipboardItem.timeStamp = Date()
                newClipboardItem.type = type
                newClipboardItem.imageData = imageData
                newClipboardItem.filePath = filePath
                newClipboardItem.imageHash = imageHash
                
                
                let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
                
                if let items = try? context.fetch(fetchRequest), items.count > self.maxItemCount {
                    
                    let fileManager = FileManager.default
                    
                    let folderPath = fileManager.temporaryDirectory
                    
                    // if the file is a tmp image in the tmp directory
                    if let item = items.first {
                        if let itemToDeletePath = item.filePath, itemToDeletePath.contains(folderPath.path()) {
                            // if the file is not still in the clipboard history
                            let items = self.findItems(content: nil, type: nil, imageHash: item.imageHash, filePath: item.filePath)
                            
                            // only want to delete file if its the only copy left
                            if items.count < 2 {
                                self.deleteTmpImage(filePath: itemToDeletePath)
                            }
                        }
                    }
                    context.delete(items.first!) // Delete the oldest item
                }
                do {
                    try context.save()
                    DispatchQueue.main.async {
                        completion?(true)
                    }
                } catch {
                    print("Failed to save context after updating clipboard items: \(error)")
                    DispatchQueue.main.async {
                        completion?(false)
                    }
                }
            }
            
        }
    }
    
    func checkLast(item: ClipboardItem?, content: String?, type: String, imageData: Data?, filePath: String?, imageHash: String?) -> Bool {
        var shouldSave = false
        
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ClipboardItem.fetchRequest()
        fetchRequest.fetchLimit = self.maxItemCount // list is in reverse order, so we need the last one
        fetchRequest.propertiesToFetch = ["content", "type", "imageData", "filePath", "imageHash"]
        fetchRequest.resultType = .dictionaryResultType
        
        
        do {
            let results = try context.fetch(fetchRequest) as? [[String: Any]]
            
            if results?.last == nil {
                shouldSave = true
                let fileManager = FileManager.default
                let folderPath = fileManager.temporaryDirectory
                
                // Clear all .png files from the temp directory
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
            else if let lastItem = results?.last {
                let lastContent = lastItem["content"] as? String
                let lastType = lastItem["type"] as? String
//                let lastImageData = lastItem["imageData"] as? Data
                let lastImageHash = lastItem["imageHash"] as? String
                let lastPath = lastItem["filePath"] as? String
                
//                if let newImageHash = imageHash,
//                   (type == "imageData" || type == "image") && (lastType == "imageData" || lastType == "image") {
                if let newImageHash = imageHash,
                    type == "image" && lastType == "image" {
                    
                    if (lastImageHash != newImageHash) || (lastImageHash == newImageHash &&  lastContent != content) {
                        shouldSave = true
                    }
                    
                    // on new copy
//                    else if let lastFileType = lastType, (lastFileType == "image" || lastFileType == "imageData") && (type == "image" || type == "imageData") {
                    else if let lastFileType = lastType, lastFileType == "image" && type == "image"  {
                        // same image, update tmp filePath to new file path
                        print("here")
                        let fileManager = FileManager.default
                        let folderPath = fileManager.temporaryDirectory
                        // if the file is a tmp image in the tmp directory {
                        if let lastFilePath = lastPath, let newFilePath = filePath, lastFilePath.contains(folderPath.path()) && lastFilePath != newFilePath {
                            let items = self.findItems(content: lastContent, type: lastFileType, imageHash: lastImageHash, filePath: lastFilePath)
                            
                            if !items.isEmpty, let item = items.first {
                                item.filePath = newFilePath
                            }
                        }
                    }
                } else {
                    if let newContent = content, newContent != lastContent {
                        if lastType == type {
                            if let lastFilePath = lastPath, let newFilePath = filePath, lastFilePath != newFilePath {
                                // both files, but different file paths
                                shouldSave = true
                            }
                        }
                        shouldSave = true  // Save if types do not match or no hash exists
                    }
                }
            }
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
        }
        return shouldSave
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
    
//    func createImageFile(item: ClipboardItem?, imageData: Data?, filePath: String?, timeStamp: Date?) {
//        guard let image = NSImage(data: imageData!) else {
//            print("Failed to create image from TIFF data.")
//            return
//        }
//
//        if let pngData = convertNSImageToPNG(image: image) {
//            let formatter = DateFormatter()
//            // 2024-08-05 at 12.39.38 PM
//            formatter.dateFormat = "yyyy-MM-dd h.mm.ss bb"
//            let fileDate = formatter.string(from: timeStamp ?? Date())
//            let splitDate = fileDate.split(separator: " ")
//            let filePathDate = splitDate[0] + " at " + splitDate[1]
//            
//            saveImageDataToFile(item: item, imageData: pngData, filePath: "Image \(filePathDate)", fileType: .png)
//        } else {
//            print("Failed to convert image to JPEG.")
//        }
//    }
    
    func createImageFile(imageData: Data?) -> URL? {
        guard let image = NSImage(data: imageData!) else {
            print("Failed to create image from TIFF data.")
            return nil
        }

        if let pngData = convertNSImageToPNG(image: image) {
            let formatter = DateFormatter()
            // 2024-08-05 at 12.39.38 PM
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

    func convertNSImageToPNG(image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
//    func saveImageDataToFile(item: ClipboardItem?, imageData: Data, filePath: String, fileType: NSBitmapImageRep.FileType) {
//        let fileManager = FileManager.default
//        let folderPath: URL
//        do {
////            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
////            folderPath = documentsURL  // Change this to .downloadsDirectory if preferred
//            folderPath = fileManager.temporaryDirectory
//
//            let fileURL = folderPath.appendingPathComponent(filePath + (fileType == .jpeg ? ".jpg" : ".png"))
//            
//            item?.filePath = fileURL.path
//            
//            try imageData.write(to: fileURL, options: .atomic)
//            
//            print("File saved: \(fileURL.path)")
//        } catch {
//            print("Error saving file: \(error)")
//        }
    
    func saveImageDataToFile(imageData: Data, filePath: String, fileType: NSBitmapImageRep.FileType) -> URL? {
        let fileManager = FileManager.default
        let folderPath: URL
        do {
//            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//            folderPath = documentsURL  // Change this to .downloadsDirectory if preferred
            folderPath = fileManager.temporaryDirectory

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
    
    // creates a comparaple hash to quickly compare images
    func hashImageData(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    deinit {
        checkTimer?.invalidate()
    }
}

