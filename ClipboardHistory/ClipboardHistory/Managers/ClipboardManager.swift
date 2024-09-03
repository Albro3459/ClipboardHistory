//
//  swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 7/26/24.
//

import Foundation
import SwiftUI
import CoreData
import KeyboardShortcuts
import QuickLookThumbnailing
import SwiftUI
import Combine
import Cocoa
import CoreData


class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    let userDefaultsManager = UserDefaultsManager.shared
    @Published var clipboardMonitor: ClipboardMonitor?
    
    
    @Published var selectedItem: ClipboardItem?
    @Published var selectedGroup: SelectedGroup?
    
    @Published var isCopied: Bool = false
    
    @Published private(set) var types = [
        ClipboardType.text,
        ClipboardType.image,
        ClipboardType.fileFolder,
        ClipboardType.group,
        ClipboardType.selectAll
    ]
    

    private init() {
        self.clipboardMonitor = ClipboardMonitor()
    }
    
    func search(fetchedClipboardGroups: FetchedResults<ClipboardGroup>, searchText: String, selectedTypes: Set<UUID>) -> [ClipboardGroup] {
        
        let selectedTypeNames: [String] = selectedTypes.map { id in
            ClipboardType.getTypeName(by: id)
        }
        
        return fetchedClipboardGroups.filter { group in
            let typeMatch: Bool
            if selectedTypes.isEmpty || selectedTypeNames.contains("Select All") || selectedTypes.count == self.types.count {
                typeMatch = true // No filtering by type when none or all are selected.
                //                return true
            }
            else if selectedTypeNames.contains("Groups") && group.count > 1 {
                typeMatch = true
                //                return true
            }
            else {
                typeMatch = group.itemsArray.contains { item in
                    if selectedTypeNames.contains("Files / Folders") {
                        // images are files too
                        return item.type?.localizedCaseInsensitiveContains("file") ?? false ||
                        item.type?.localizedCaseInsensitiveContains("folder") ?? false ||
                        item.type?.localizedCaseInsensitiveContains("image") ?? false
                    }
                    else if selectedTypeNames.contains("Images") {
                        // files can be images if they have an imageHash
                        return item.imageHash != nil ||
                        item.type?.localizedCaseInsensitiveContains("image") ?? false
                    }
                    else {
                        // Check against other types.
                        return selectedTypeNames.contains(where: { typeName in
                            item.type?.localizedCaseInsensitiveContains(typeName) ?? false
                        })
                    }
                }
            }
            
            if searchText.isEmpty {
                return typeMatch
                //                return true
            }
            else {
                // Further filter by searchText if it is not empty.
                var searchTextMatch = false
                let searchText = searchText.lowercased()
                
                if ["file", "fil", "fi", "doc", "docu", "docum", "docume", "documen", "document", "pd", "pdf"].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.itemsArray.contains(where: { $0.content?.localizedCaseInsensitiveContains(searchText) ?? false }) ||
                    group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains(searchText) ?? false }) ||
                    group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("image") ?? false })
                }
                else if ["zip", "rar", "tar"].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.itemsArray.contains(where: { $0.content?.localizedCaseInsensitiveContains(searchText) ?? false }) ||
                    group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains(searchText) ?? false }) ||
                    group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("zipFile") ?? false })
                }
                else if ["group", "grou", "gro", "gr"].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.count > 1
                }
                else if ["image", "ima", "im", "pic", "pict", "pictu", "pictur", "picture"].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.itemsArray.contains(where: { $0.imageHash != nil }) ||
                    group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("image") ?? false })
                }
                else if ["text", "tex", "te", "tx", "txt", "note", "not"].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("text") ?? false })
                }
                else if ["folder", "fol", "fo", "dir", "dire", "direc", "direct", "directo", "director", "directory"].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("folder") ?? false })
                }
                else if ["alias", "alia", "ali"/*, "symlink", "symlin", "symli", "syml", "sym", "lin", "link"*/].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("alias") ?? false })
                }
                else if ["app", "ap"].contains(where: { searchText.hasPrefix($0) }) {
                    searchTextMatch = group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("calendarApp") ?? false }) ||
                                        group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("photoBoothApp") ?? false }) ||
                                        group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("settingsApp") ?? false }) ||
                                        group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("app") ?? false }) ||
                                        group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains(searchText) ?? false }) ||
                                        group.itemsArray.contains(where: { $0.content?.localizedCaseInsensitiveContains("app") ?? false }) ||
                                        group.itemsArray.contains(where: { $0.content?.localizedCaseInsensitiveContains(searchText) ?? false })
                }
//                else if ["symlink", "symlin", "symli", "syml", "sym", "lin", "link", "ali", "alia", "alias"].contains(where: { searchText.hasPrefix($0) }) {
//                    searchTextMatch = group.itemsArray.contains(where: { $0.type?.localizedCaseInsensitiveContains("symlink") ?? false })
//                }
                else {
                    searchTextMatch = group.itemsArray.contains( where: {
                        ($0.type?.lowercased().contains(searchText) ?? false) ||
                        ($0.content?.lowercased().contains(searchText) ?? false)
                    })
                }
                return searchTextMatch && typeMatch
            }
        }
    }
    
    // copying a group with just 1 item
    func copySingleGroup() {
        guard let items = selectedGroup?.group.itemsArray, let item = items.first else {
            print("No item to copy")
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let monitor = clipboardMonitor {
            monitor.isInternalCopy = true
        }
        
        switch item.type {
        case "text":
            if let content = item.content {
                if copied(item: item) {
                    pasteboard.setString(content, forType: .string)
                }
            }
        case "image", "file", "zipFile", "dmgFile", "randomFile", "execFile", "folder", "alias", "app":
            if let filePath = item.filePath {
                let url = URL(fileURLWithPath: filePath)
                if copied(item: item) {
                    pasteboard.writeObjects([url as NSURL])
                    print(url.path)
                }
            }
        default:
            print("unsupported item for copying: \(item.type ?? "nil type")")
        }
    }
           
    // copying an item out of a group
    func copySelectedItemInGroup() {
        guard let item = selectedItem, let group = selectedGroup, item.group == group.group else {
            print("No item selected")
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let monitor = clipboardMonitor {
            monitor.isInternalCopy = true
        }
        
        switch item.type {
        case "text":
            if let content = item.content {
                if copied(item: item) {
                    pasteboard.setString(content, forType: .string)
                }            }
        case "image", "file", "zipFile", "dmgFile", "randomFile", "execFile", "folder", "alias", "app":
            if let filePath = item.filePath {
                let url = URL(fileURLWithPath: filePath)
                if copied(item: item) {
                    pasteboard.writeObjects([url as NSURL])
                    print(url.path)
                }
            }
        default:
            print("unsupported group item for copying: \(item.type ?? "nil type")")
        }
    }
    
    // copying a whole group
    func copySelectedGroup() {
        guard let items = selectedGroup?.group.itemsArray, !items.isEmpty else {
            print("No items to copy or selected group is nil")
            return
        }
        if items.count == 1, selectedItem == nil {
            self.copySingleGroup()
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let monitor = clipboardMonitor {
            monitor.isInternalCopy = true
        }
        
        var array: [NSPasteboardWriting] = []
        
        for item in items {
            
            switch item.type {
            case "text":
                if let content = item.content {
                    array.append(content as NSString)
                }
            case "image", "file", "zipFile", "dmgFile", "randomFile", "execFile", "folder", "alias", "app":
                if let filePath = item.filePath {
                    let url = URL(fileURLWithPath: filePath)
                    print(url.path)
                    array.append(url as NSURL)
                }
            default:
                print("unsupported item in this group for copying: \(item.type ?? "nil type")")
            }
        }
        
        if copied(item: nil) {
            if pasteboard.writeObjects(array as [NSPasteboardWriting]) {
//                copied()
            }
            else {
                print("Failed to write objects to pasteboard.")
                
            }
        }
    }
            
    func copied(item: ClipboardItem?) -> Bool {
        DispatchQueue.main.async {
            self.isCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isCopied = false
            }
        }
        return true
        
        // code that actually checks if it is going to copy, buttt I want to see the copy popop for user feedback
//        if let item = item {
//            if clipboardMonitor?.checkLast(group: nil, item: item, context: nil) == true {
//                DispatchQueue.main.async {
//                    self.isCopied = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        self.isCopied = false
//                    }
//                }
//                return true
//            }
//            else {
//                return false
//            }
//        }
//        else if let selectGroup = self.selectedGroup {
//            if clipboardMonitor?.checkLast(group: selectGroup.group, item: nil, context: nil) == true {
//                DispatchQueue.main.async {
//                    self.isCopied = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        self.isCopied = false
//                    }
//                }
//                return true
//            }
//            else {
//                return false
//            }
//        }
//        else {
//            return false
//        }
    }
    
    func deleteGroup(group: ClipboardGroup?, selectList: [SelectedGroup], viewContext: NSManagedObjectContext) {
        
        if let group = group {
            let selectedGroup = group.GetSelecGroupObj(group, list: selectList)
            let index = GetGroupIndex(group: selectedGroup, selectList: selectList)
            
            for item in group.itemsArray {
                deleteItem(item: item, viewContext: viewContext, shouldSave: false)
            }
            
            viewContext.delete(group)
            
            if selectList.count > 1 {
                // only if user wants this setting on
//                self.selectedGroup = selectList[0]
                if selectList.count == 2 {
                    self.selectedGroup = selectList[0]
                }
                else if selectList.count > 2, let index = index {
                    if index == selectList.count - 1 {
                        let nextIndex = index - 1
                        self.selectedGroup = selectList[nextIndex]
                    }
                    else if index <= selectList.count - 2 {
                        let nextIndex = index + 1
                        self.selectedGroup = selectList[nextIndex]
                    }
                    
                }
            }
            else if selectList.count <= 1 {
                // when I deleted the last group
                self.selectedGroup = nil
                self.selectedItem = nil
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving managed object context: \(error)")
            }
        }
    }
    
    func deleteItem(item: ClipboardItem, viewContext: NSManagedObjectContext, shouldSave: Bool) {
        
        if let selectGroup = self.selectedGroup, item.group == selectGroup.group {
            //cleaning up tmp image files first
            if let imageHash = item.imageHash, let filePath = item.filePath, !filePath.isEmpty {
                
                let folderPath = clipboardMonitor?.tmpFolderPath
                
                if filePath.contains(folderPath!.path()) {
                    
                    let items = clipboardMonitor?.findItems(content: nil, type: nil, imageHash: imageHash, filePath: filePath, context: nil)
                    
                    // only want to delete file if its the only copy left
                    if items!.count < 2 {
                        print(items!.count)
                        clipboardMonitor?.deleteTmpImage(filePath: filePath)
                    }
                }
            }
            
            
            // when we delete an item inside a group
            // we need to maintain the right selection
//            print("***in itemm")
            selectGroup.group.count -= 1
            
            let groupCount = selectGroup.group.count
            if selectGroup.group.count == 1 {
                selectGroup.isExpanded = false
            }
            
            // selecting the next index after deleting
            if groupCount <= 1 {
                // if there is one item, it is no longer a group view, so no selectedItem
                self.selectedItem = nil
            }
            else if groupCount >= 2 {
                let itemIndex = GetItemIndexInGroup(item: item)
                if let index = itemIndex {
                    if index == groupCount {
                        // if its the last item, select the next last item
                        self.selectedItem = selectGroup.group.itemsArray[index - 1]
                    }
                    else if index == 0 || index < groupCount {
                        self.selectedItem = selectGroup.group.itemsArray[index + 1]
                    }
                }
            }
            
            
            viewContext.delete(item)
            
            if shouldSave {
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving managed object context: \(error)")
                }
            }
        }
        else {
            print("Error deleting item, not in the selected group")
        }
    }
    
    private func GetGroupIndex(group: SelectedGroup?, selectList: [SelectedGroup]) -> Int? {
        if let group = group {
            var currentIndex: Int?
            currentIndex = selectList.firstIndex(of: group)
            if currentIndex == nil {
                if !selectList.isEmpty {
                    selectedGroup = selectList[0]
                    if let group = selectedGroup?.group, group.count == 1 {
                        selectedGroup?.selectedItem = selectedGroup?.group.itemsArray.first
                    }
                    currentIndex = 0
                }
            }
            return currentIndex
        }
        return nil
    }
    
    private func GetItemIndexInGroup(item: ClipboardItem) -> Int? {
        if let group = selectedGroup?.group {
            if let currentIndex = group.itemsArray.firstIndex(of: item) {
                return currentIndex
            }
            else {
                return nil
            }
        }
        return nil
    }
    

    func toggleExpansion(for group: SelectedGroup) {
        if let currentGroup = selectedGroup, currentGroup == group {
            currentGroup.isExpanded.toggle()
            print("toggling")

            objectWillChange.send()
        }
    }
    
    func expand(for group: SelectedGroup) {
        if let currentGroup = selectedGroup, currentGroup == group {
            DispatchQueue.main.async {
                
                currentGroup.isExpanded = true
                print("expanding")
                
                self.objectWillChange.send()
            }
        }
    }
    
    func expandAll(for list: [SelectedGroup]) {
        DispatchQueue.main.async {
            for selectedGroup in list {
                if selectedGroup.group.count > 1 {
                    selectedGroup.isExpanded = true
                }
            }
            print("expanded groups")
            self.objectWillChange.send()
        }
    }
    
    func contract(for group: SelectedGroup) {
        if let currentGroup = selectedGroup, currentGroup == group {
            DispatchQueue.main.async {
                
                currentGroup.isExpanded = false
                print("contracting")
                
                self.objectWillChange.send()
            }
        }
    }
    
    func contractAll(for list: [SelectedGroup]) {
        DispatchQueue.main.async {
            
            for selectedGroup in list {
                selectedGroup.isExpanded = false
            }
            print("contracted groups")
            self.objectWillChange.send()
        }
    }
    
    func openFolder(filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    // used to also copy temp images to desktop before opening, now thats commented out
    func openFile(filePath: String) {
        // if file is tmp image, copy to desktop, then open
            // else, open the file
        
        
        let fileURL = URL(fileURLWithPath: filePath)
//        let fileName = fileURL.lastPathComponent
//        
//        let regexPattern = "^Image \\d{4}-\\d{2}-\\d{2} at \\d{1,2}\\.\\d{2}\\.\\d{2} (AM|PM)\\.png$"
//        
//        do {
//            let regex = try NSRegularExpression(pattern: regexPattern)
//            let range = NSRange(location: 0, length: fileName.utf16.count)
            
            // copies temp images to Desktop, we are no longer going to use that
//            if let clipboardMonitor = clipboardMonitor, regex.firstMatch(in: fileName, options: [], range: range) != nil && fileURL.path.hasPrefix(clipboardMonitor.tmpFolderPath.path) {
//                                // File matches the regex pattern, copy it to the desktop
//                let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
//                let destinationURL = desktopURL.appendingPathComponent(fileName)
//                
//                
//                do {
//                    try FileManager.default.copyItem(at: fileURL, to: destinationURL)
//                    print("File copied to Desktop: \(destinationURL.path)")
//                    // Check if the file exists and open it
//                    if FileManager.default.fileExists(atPath: destinationURL.path) {
//                        NSWorkspace.shared.open(destinationURL)
//                    } else {
//                        print("File does not exist at path: \(destinationURL.path)")
//                    }
//                } catch {
//                    print("Failed to copy file to Desktop: \(error)")
//                }
//            }
//            else {
                // Check if the file exists and open it
                if FileManager.default.fileExists(atPath: filePath) {
                    NSWorkspace.shared.open(fileURL)
                } else {
                    print("File does not exist at path: \(filePath)")
                }
//            }
//        } catch {
//            print("Invalid regex pattern: \(error)")
//        }
    }
    
    private var lastPasteNoFormatTime: Date?
    
    public func pasteNoFormatting() {
        
        DispatchQueue.main.async {

            self.clipboardMonitor?.isPasteNoFormattingCopy = true
            
            let pasteboard = NSPasteboard.general
            
            // Check for file URLs first
            if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let _ = fileUrls.first {
            }
            else if let imageData = pasteboard.data(forType: .tiff), let _ = NSImage(data: imageData) {
            }
            else if let content = pasteboard.string(forType: .string) {
                self.updatePasteboard(with: content)
            } else if let rtfData = pasteboard.data(forType: .rtf) {
                // Convert RTF to plain text
                if let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                    let plainText = attributedString.string
                    self.updatePasteboard(with: plainText)
                }
            } else if let htmlData = pasteboard.data(forType: .html) {
                // Convert HTML to plain text
                if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                    let plainText = attributedString.string
                    self.updatePasteboard(with: plainText)
                }
            }
            
            self.paste()
        }
    }
    
    private func updatePasteboard(with plainText: String) {
        
        let pasteboard = NSPasteboard.general
        
        pasteboard.clearContents()
        pasteboard.setString(plainText, forType: .string)
        self.paste()
    }
    
    func paste() {
        let now = Date()
        if let lastPasteNoFormatTime = lastPasteNoFormatTime, now.timeIntervalSince(lastPasteNoFormatTime) < 0.33 {
            return
        }
        self.lastPasteNoFormatTime = now
        
        
        DispatchQueue.main.async {
            
            let cmdFlag = CGEventFlags.maskCommand
            let vCode: CGKeyCode = 9 // Key code for 'V' on a QWERTY keyboard
            
            let source = CGEventSource(stateID: .combinedSessionState)
            source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents], state: .eventSuppressionStateSuppressionInterval)
            
            let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true)
            let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false)
            keyVDown?.flags = cmdFlag
            keyVUp?.flags = cmdFlag
            keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
            
        }
    }

}
