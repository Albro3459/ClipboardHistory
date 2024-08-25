//
//  KeyboardShortcut.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/24/24.
//

import Foundation

struct KeyboardShortcut: Codable {
    let modifiers: [String] // ["cmd", "shift"], ["option"], etc.
    let key: String
}
