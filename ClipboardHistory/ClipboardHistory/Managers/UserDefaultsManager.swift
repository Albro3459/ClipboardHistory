//
//  UserDefaultsManager.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/28/24.
//

import Foundation
import AppKit
import Cocoa
import SwiftUI
import KeyboardShortcuts


class UserDefaultsManager {
    static let shared = UserDefaultsManager()

//  User Defaults
    var appName: String
    
    var darkMode: Bool
    var windowWidth: CGFloat
    var windowHeight: CGFloat
    var windowLocation: String
    var windowPopOut: Bool  // pop out of the menu button when clicked
    var canWindowFloat: Bool
    var hideWindowWhenNotSelected: Bool
    var windowOnAllDesktops: Bool
    
    var pauseCopying: Bool
    
    var noDuplicates: Bool
    var maxStoreCount: Int
    var canCopyFilesOrFolders: Bool
    var canCopyImages: Bool
    
    var pasteWithoutFormatting: Bool
    
    var pasteWithoutFormattingShortcut: KeyboardShortcut
    var toggleWindowShortcut: KeyboardShortcut
    var resetWindowShortcut: KeyboardShortcut
    
    init() {
        let decoder = JSONDecoder()
        
        self.appName = UserDefaults.standard.string(forKey: "appName") ?? "test App Name"
        
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.windowWidth = CGFloat(UserDefaults.standard.float(forKey: "windowWidth"))
        self.windowHeight = CGFloat(UserDefaults.standard.float(forKey: "windowHeight"))
        self.windowLocation = UserDefaults.standard.string(forKey: "windowLocation") ?? "bottomRight"
        self.windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
        self.canWindowFloat = UserDefaults.standard.bool(forKey: "canWindowFloat")
        if self.canWindowFloat {
            self.hideWindowWhenNotSelected = false
        }
        else {
            self.hideWindowWhenNotSelected = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")
        }
        self.windowOnAllDesktops = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")

        self.pauseCopying = UserDefaults.standard.bool(forKey: "pauseCopying")
        
        self.maxStoreCount = UserDefaults.standard.integer(forKey: "maxStoreCount")
        self.noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
        self.canCopyFilesOrFolders = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
        self.canCopyImages = UserDefaults.standard.bool(forKey: "canCopyImages")

        self.pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
        
        if let data = UserDefaults.standard.data(forKey: "pasteWithoutFormattingShortcut") {
            self.pasteWithoutFormattingShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            self.pasteWithoutFormattingShortcut = KeyboardShortcut(modifiers: ["cmd", "shift"], key: "v")
        }
        
        if let data = UserDefaults.standard.data(forKey: "toggleWindowShortcut") {
            self.toggleWindowShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            self.toggleWindowShortcut = KeyboardShortcut(modifiers: ["cmd", "shift"], key: "c")
        }
        
        if let data = UserDefaults.standard.data(forKey: "resetWindowShortcut") {
            self.resetWindowShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            self.resetWindowShortcut = KeyboardShortcut(modifiers: ["option"], key: "r")
        }
    }
}
