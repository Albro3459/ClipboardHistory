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
        case "imageData":
            if let imageData = item.imageData {
                pasteboard.setData(imageData, forType: .tiff)
                copied()
            }
        case "image", "file", "folder", "alias":
            if let fileName = item.fileName {
                let url = URL(fileURLWithPath: fileName)
                pasteboard.writeObjects([url as NSURL])
                copied()
            }
        default:
            break
        }
    }
    
    func copied() {
        guard let item = selectedItem,
              let itemType = item.type,
              item.content != nil || item.imageData != nil || item.fileName != nil else {
//            print("Selected item or required properties are nil")
            return
        }

        if clipboardMonitor?.checkLast(content: item.content, type: itemType, imageData: item.imageData, fileName: item.fileName) == true {
            DispatchQueue.main.async {
                self.isCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.isCopied = false
                }
            }
        }
    }
}
