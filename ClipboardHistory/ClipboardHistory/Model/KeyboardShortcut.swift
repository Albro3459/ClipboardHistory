//
//  KeyboardShortcut.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/24/24.
//

import Foundation
import AppKit
import Cocoa
import SwiftUI

struct KeyboardShortcut: Codable {
    let modifiers: [String] // ["cmd", "shift"], ["option"], etc.
    let key: String

    func toModifierFlags() -> NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        if modifiers.contains("cmd") {
            flags.insert(.command)
        }
        if modifiers.contains("shift") {
            flags.insert(.shift)
        }
        if modifiers.contains("option") {
            flags.insert(.option)
        }
        if modifiers.contains("control") {
            flags.insert(.control)
        }
        return flags
    }
    
    func toKeyEquivalent() -> String? {
        switch key.lowercased() {
            
        // Special keys
        case "return": return "\r"
        case "enter": return "\r"
        case "delete": return "\u{8}" // Backspace
        case "tab": return "\t"
        case "space": return " "
        case "escape": return "\u{1B}"
        
        // Arrow keys
        case "uparrow": return String(UnicodeScalar(NSUpArrowFunctionKey)!)
        case "downarrow": return String(UnicodeScalar(NSDownArrowFunctionKey)!)
        case "leftarrow": return String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case "rightarrow": return String(UnicodeScalar(NSRightArrowFunctionKey)!)

        // Function keys (F1-F12)
        case "f1": return String(UnicodeScalar(NSF1FunctionKey)!)
        case "f2": return String(UnicodeScalar(NSF2FunctionKey)!)
        case "f3": return String(UnicodeScalar(NSF3FunctionKey)!)
        case "f4": return String(UnicodeScalar(NSF4FunctionKey)!)
        case "f5": return String(UnicodeScalar(NSF5FunctionKey)!)
        case "f6": return String(UnicodeScalar(NSF6FunctionKey)!)
        case "f7": return String(UnicodeScalar(NSF7FunctionKey)!)
        case "f8": return String(UnicodeScalar(NSF8FunctionKey)!)
        case "f9": return String(UnicodeScalar(NSF9FunctionKey)!)
        case "f10": return String(UnicodeScalar(NSF10FunctionKey)!)
        case "f11": return String(UnicodeScalar(NSF11FunctionKey)!)
        case "f12": return String(UnicodeScalar(NSF12FunctionKey)!)

        // Default case for unsupported keys
        default: return key.lowercased()
        }
    }
}
