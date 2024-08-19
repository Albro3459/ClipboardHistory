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
            
    func copySelectedItem() {
        guard let item = selectedItem else {
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
//        case "imageData":
//            if let imageData = item.imageData {
//                if let filePath = selectedItem?.filePath {
//                    let url = URL(fileURLWithPath: filePath)
//                    pasteboard.writeObjects([url as NSURL])
////                    print(url.path())
//                    copied()
//                }
//                else {
//                    pasteboard.setData(imageData, forType: .tiff)
//                    copied()
//                }
//            }
        case "image", "file", "folder", "alias":
            if let filePath = item.filePath {
                let url = URL(fileURLWithPath: filePath)
                pasteboard.writeObjects([url as NSURL])
                print(url.path)
                copied()
            }
        default:
            break
        }
    }
    
    func copySelectedGroup() {
        if let items = selectedGroup?.group.itemsArray {
            var array: [ClipboardItem] = []
            for item in items {
                array.append(item)
            }
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
