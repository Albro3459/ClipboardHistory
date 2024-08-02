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
            }
        case "imageData":
            if let imageData = item.imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
        case "image", "file", "folder", "alias":
            if let fileName = item.fileName {
                let url = URL(fileURLWithPath: fileName)
                pasteboard.writeObjects([url as NSURL])
            }
        default:
            break
        }
    }
}
