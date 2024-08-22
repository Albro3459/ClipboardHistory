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
    @Published var selectedItem: ClipboardItem?
    @Published var selectedGroup: SelectedGroup?
    
    @Published var isCopied: Bool = false
        
    var clipboardMonitor: ClipboardMonitor?

    init() {
        self.clipboardMonitor = ClipboardMonitor()
    }
    
    // copying a group with just 1 item
    func copySingleGroup() {
        guard let items = selectedGroup?.group.itemsArray, let item = items.first else {
            print("No item to copy")
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case "text":
            if let content = item.content {
                pasteboard.setString(content, forType: .string)
                copied()

            }
        case "image", "file", "folder", "alias":
            if let filePath = item.filePath {
                let url = URL(fileURLWithPath: filePath)
                pasteboard.writeObjects([url as NSURL])
                print(url.path)
                copied()

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
        
        switch item.type {
        case "text":
            if let content = item.content {
                pasteboard.setString(content, forType: .string)
                copied()
            }
        case "image", "file", "folder", "alias":
            if let filePath = item.filePath {
                let url = URL(fileURLWithPath: filePath)
                pasteboard.writeObjects([url as NSURL])
                print(url.path)
                copied()
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
            copySingleGroup()
            return
        }

        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var array: [NSPasteboardWriting] = []
        
        for item in items {
            
            switch item.type {
            case "text":
                if let content = item.content {
//                    pasteboard.setString(content, forType: .string)
                    array.append(content as NSString)
                }
            case "image", "file", "folder", "alias":
                if let filePath = item.filePath {
                    let url = URL(fileURLWithPath: filePath)
//                    pasteboard.writeObjects([url as NSURL])
                    print(url.path)
                    array.append(url as NSURL)
                }
            default:
                print("unsupported item in this group for copying: \(item.type ?? "nil type")")
            }
        }
        
        if pasteboard.writeObjects(array as [NSPasteboardWriting]) {
            copied()
        }
        else {
            print("Failed to write objects to pasteboard.")

        }
        
    }
            
    func copied() {
//        guard let item = selectedItem,
//              let itemType = item.type,
//              item.content != nil || item.imageData != nil || item.filePath != nil else {
////            print("Selected item or required properties are nil")
//            return
//        }

//        if clipboardMonitor?.checkLast(group: selectedGroup!, context: nil) == true {
//            DispatchQueue.main.async {
//                self.isCopied = true
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    self.isCopied = false
//                }
//            }
//        }
    }
    
    func deleteGroup(group: ClipboardGroup?, selectList: [SelectedGroup], viewContext: NSManagedObjectContext) {
        
        if let group = group {
            let selectedGroup = group.GetSelecGroupObj(group, list: selectList)
            let index = GetGroupIndex(group: selectedGroup, selectList: selectList)
            
            for item in group.itemsArray {
                deleteItem(item: item, viewContext: viewContext, isCalledByGroup: true)
            }
            
            viewContext.delete(group)
            
            if selectList.count > 1 {
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
    
    func deleteItem(item: ClipboardItem, viewContext: NSManagedObjectContext, isCalledByGroup: Bool) {
        
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
            print("***in itemm")
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
//            else if groupCount == 1 {
//                self.selectedItem = selectGroup.group.itemsArray[0]
//            }
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
            
            if !isCalledByGroup {
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
                        //                        print("here")
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
            currentGroup.isExpanded = true
            print("expanding")

            objectWillChange.send()
        }
    }
    
    func contract(for group: SelectedGroup) {
        if let currentGroup = selectedGroup, currentGroup == group {
            currentGroup.isExpanded = false
            print("contracting")

            objectWillChange.send()
        }
    }
}
