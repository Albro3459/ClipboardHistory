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
import Combine

class UserDefaultsManager : ObservableObject {
    static let shared = UserDefaultsManager()
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

//  User Defaults
    var appName: String
    
    // have to do this to update the ui state without interacting with the app.
        // => essentially when I change darkMode and save the settings
    @Published var darkMode: Bool
//    {
//        didSet {
//            darkModeSubject.send()
//        }
//    }
//    let darkModeSubject = PassthroughSubject<Void, Never>()
    
    var windowWidth: CGFloat
    var windowHeight: CGFloat
    var windowLocation: String
    var windowPopOut: Bool  // pop out of the menu button when clicked
//    var onlyPopOutWindow: Bool
    var canWindowFloat: Bool
    var hideWindowWhenNotSelected: Bool
    var windowOnAllDesktops: Bool
    
    var pauseCopying: Bool
    
    var noDuplicates: Bool
    var maxStoreCount: Int
    var canCopyFilesOrFolders: Bool
    var canCopyImages: Bool
    
    var enterKeyHidesAfterCopy: Bool
    var pasteWithoutFormatting: Bool
    
    var pasteWithoutFormattingShortcut: KeyboardShortcut
    var toggleWindowShortcut: KeyboardShortcut
    var resetWindowShortcut: KeyboardShortcut
    
    private init() {
        
        self.appName = UserDefaults.standard.string(forKey: "appName") ?? "test App Name"
        
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.windowWidth = CGFloat(UserDefaults.standard.float(forKey: "windowWidth"))
        self.windowHeight = CGFloat(UserDefaults.standard.float(forKey: "windowHeight"))
        self.windowLocation = UserDefaults.standard.string(forKey: "windowLocation") ?? "bottomRight"
        self.windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
//        self.onlyPopOutWindow = UserDefaults.standard.bool(forKey: "onlyPopOutWindow")
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

        self.enterKeyHidesAfterCopy = UserDefaults.standard.bool(forKey: "enterKeyHidesAfterCopy")
        self.pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
        
        if let data = UserDefaults.standard.data(forKey: "pasteWithoutFormattingShortcut") {
            self.pasteWithoutFormattingShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            print("pasteWithoutFormattingShortcut Decode Failed!!")
            self.pasteWithoutFormattingShortcut = KeyboardShortcut(modifiers: ["cmd", "shift"], key: "v")
        }
        
        if let data = UserDefaults.standard.data(forKey: "toggleWindowShortcut") {
            self.toggleWindowShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            print("toggleWindowShortcut Decode Failed!!")
            self.toggleWindowShortcut = KeyboardShortcut(modifiers: ["cmd", "shift"], key: "c")
        }
        
        if let data = UserDefaults.standard.data(forKey: "resetWindowShortcut") {
            self.resetWindowShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            print("resetWindowShortcut Decode Failed!!")
            self.resetWindowShortcut = KeyboardShortcut(modifiers: ["option"], key: "r")
        }
    }
    
    func saveShortcuts(savePasteWithoutFormattingShortcut: Bool) {
        if let data = try? encoder.encode(pasteWithoutFormattingShortcut) {
            UserDefaults.standard.set(data, forKey: "pasteWithoutFormattingShortcut")
        }
        if let data = try? encoder.encode(toggleWindowShortcut) {
            UserDefaults.standard.set(data, forKey: "toggleWindowShortcut")
        }
        if let data = try? encoder.encode(resetWindowShortcut) {
            UserDefaults.standard.set(data, forKey: "resetWindowShortcut")
        }
        
        KeyboardShortcuts.reset(.toggleWindow)
        KeyboardShortcuts.reset(.resetWindow)
        KeyboardShortcuts.reset(.hideWindow)
        if savePasteWithoutFormattingShortcut {
            KeyboardShortcuts.reset(.pasteNoFormatting)
        }
    }
    
    func updateAll(savePasteWithoutFormattingShortcut: Bool) {
        
//        if saveShortcuts {
        self.saveShortcuts(savePasteWithoutFormattingShortcut: savePasteWithoutFormattingShortcut)
//        }
            
        self.appName = UserDefaults.standard.string(forKey: "appName") ?? "test App Name"
        
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.windowWidth = CGFloat(UserDefaults.standard.float(forKey: "windowWidth"))
        self.windowHeight = CGFloat(UserDefaults.standard.float(forKey: "windowHeight"))
        self.windowLocation = UserDefaults.standard.string(forKey: "windowLocation") ?? "Bottom Right"
        self.windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
//        self.onlyPopOutWindow = UserDefaults.standard.bool(forKey: "onlyPopOutWindow")
        self.canWindowFloat = UserDefaults.standard.bool(forKey: "canWindowFloat")
        if self.canWindowFloat {
            self.hideWindowWhenNotSelected = false
        }
        else {
//            print("updated hiding")
            self.hideWindowWhenNotSelected = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")
        }
        self.windowOnAllDesktops = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")

        self.pauseCopying = UserDefaults.standard.bool(forKey: "pauseCopying")
        self.maxStoreCount = UserDefaults.standard.integer(forKey: "maxStoreCount")
        self.noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
        self.canCopyFilesOrFolders = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
        self.canCopyImages = UserDefaults.standard.bool(forKey: "canCopyImages")

        self.enterKeyHidesAfterCopy = UserDefaults.standard.bool(forKey: "enterKeyHidesAfterCopy")
        self.pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
                
        ClipboardManager.shared.clipboardMonitor?.reloadVars()
        
//        print("done updating")
    }
}
