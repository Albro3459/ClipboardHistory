//
//  ClipboardManager.swift
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
        if items.count == 1, selectedItem != nil {
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
