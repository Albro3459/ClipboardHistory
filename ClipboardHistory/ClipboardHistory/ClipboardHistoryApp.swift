//
//  ClipboardHistoryApp.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import AppKit
import Cocoa
import SwiftUI
import KeyboardShortcuts

@main
struct ClipboardHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    
    init() {
        //have to register first!!
        self.registerUserDefaults()
                
    }
    
    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//                .environmentObject(appDelegate.clipboardManager!)
//                .environmentObject(appDelegate.windowManager!)
//                .environmentObject(appDelegate.menuManager!)
//        }
        
        Settings { // have to do this to get the empty window to not appear
            EmptyView()
        }
    }
    
    private func registerUserDefaults() {
        // User Defaults
        
        let encoder = JSONEncoder()
        
        let defaults: [String: Any] = [
            "appName": "ClipboardHistory",
            
            "darkMode": true,
            "windowWidth": 300,
            "windowHeight": 500,
            "windowLocation": "Bottom Right",
            "windowPopOut": false, // TODO
//            "onlyPopOutWindow": false, // TODO
            "canWindowFloat": false,
            "hideWindowWhenNotSelected": false,
            "windowOnAllDesktops": true,
            
            "pauseCopying": false,
            
            "maxStoreCount": 50,
            "noDuplicates": true,
            "canCopyFilesOrFolders": true,
            "canCopyImages": true,
            
            "pasteWithoutFormatting": false,
            
            // out of app shortcuts
            "pasteWithoutFormattingShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["command", "shift"], key: "v")),
            "toggleWindowShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["command", "shift"], key: "c")),
            "resetWindowShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["option"], key: "r"))
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var statusBarItem: NSStatusItem?
    
    let persistenceController: PersistenceController?
    let userDefaultsManager: UserDefaultsManager?
    let windowManager: WindowManager?
    let menuManager: MenuManager?
//    let menuManager = MenuManager.shared
//    let windowManager = WindowManager.shared
    let clipboardManager: ClipboardManager?
    
    private var lastToggleTime: Date?
    private var lastPasteNoFormatTime: Date?
            
    override init() {
        self.persistenceController = PersistenceController.shared
        self.userDefaultsManager = UserDefaultsManager.shared
        self.windowManager = WindowManager.shared
        self.menuManager = MenuManager.shared
        self.clipboardManager = ClipboardManager.shared
        
        super.init()
        
        self.menuManager?.windowManager = self.windowManager
        self.windowManager?.menuManager = self.menuManager
        
        setupGlobalHotKey()
    }

    func setupGlobalHotKey() {
        
        let now = Date()
        if let lastToggleTime = lastToggleTime, now.timeIntervalSince(lastToggleTime) < 0.33 {
//                        print("Toggle too fast, ignoring.")
            return
        }
        self.lastToggleTime = now
        
        KeyboardShortcuts.reset(.toggleWindow)
        KeyboardShortcuts.reset(.resetWindow)
        KeyboardShortcuts.reset(.hideWindow)
        KeyboardShortcuts.reset(.toggleWindow)
        
        
        KeyboardShortcuts.onKeyDown(for: .toggleWindow) {
            if UserDefaultsManager.shared.windowPopOut {
                self.windowManager?.togglePopOutWindow(nil)
            }
            else {
                self.windowManager?.toggleWindow()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .resetWindow) {
            if UserDefaultsManager.shared.windowPopOut {
                self.windowManager?.resetPopOutWindow()
            }
            else {
                self.windowManager?.resetWindow()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .hideWindow) {
            if UserDefaultsManager.shared.windowPopOut {
                self.windowManager?.hidePopOutWindow()
            }
            else {
                self.windowManager?.hideWindow()
            }
        }
        
        if let userDefaultsManager = self.userDefaultsManager, userDefaultsManager.pasteWithoutFormatting {
            KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                self.clipboardManager?.pasteNoFormatting()
            }
        }
        else { // otherwise free it up, so I dont consume the keystroke
            KeyboardShortcuts.disable(.pasteNoFormatting)
        }
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
//        setupGlobalHotKey()
        
        self.windowManager?.setupApp()
        
        if !UserDefaultsManager.shared.windowPopOut && UserDefaultsManager.shared.hideWindowWhenNotSelected {
            NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: nil)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//        print("Dock icon clicked!")
        
        menuManager?.updateMainMenu(isCopyingPaused: nil)
        
        return true
    }
    
    
    
    
    
//    @objc func windowDidAppear(_ notification: Notification) {
//        print("window appeared")
//        NSApplication.shared.mainMenu = nil
//        self.menuManager.updateMainMenu(isCopyingPaused: nil)
//    }
    
    @objc func windowDidResignKey(_ notification: Notification) {
        print("Window did resign key (unfocused)")
        // App lost focus
        
        print(UserDefaultsManager.shared.hideWindowWhenNotSelected)
        if UserDefaultsManager.shared.hideWindowWhenNotSelected {
            // Check if the current main window is the settings window
            if let mainWindow = NSApplication.shared.mainWindow, mainWindow.title == "ClipboardHistory" {
                print("The main window is the settings window, not hiding it.")
            } else {
                windowManager?.hideWindow()
            }
        }
    }
    
    
    
    
    
    func applicationWillTerminate(_ notification: Notification) {
        // Remove observers
//        NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: nil)
        if let userDefaultsManager = userDefaultsManager, userDefaultsManager.hideWindowWhenNotSelected {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didResignKeyNotification, object: nil)
        }
    }
}

extension KeyboardShortcuts.Name {
    static var toggleWindow: Self {
        let userDefaultsManager = UserDefaultsManager.shared
        return Self("toggleWindow", default: .from(userDefaultsManager.toggleWindowShortcut))
    }
    
    static var hideWindow = Self("hideWindow", default: .init(.h, modifiers: [.command]))

    static var pasteNoFormatting: Self {
        let userDefaultsManager = UserDefaultsManager.shared
        return Self("pasteNoFormatting", default: .from(userDefaultsManager.pasteWithoutFormattingShortcut))
    }

    static var resetWindow: Self {
        let userDefaultsManager = UserDefaultsManager.shared
        return Self("resetWindow", default: .from(userDefaultsManager.resetWindowShortcut))
    }
    
}

extension KeyboardShortcuts.Shortcut {
    static func from(_ customShortcut: KeyboardShortcut) -> Self {
        let modifiers: NSEvent.ModifierFlags = {
            var flags = NSEvent.ModifierFlags()
            if customShortcut.modifiers.contains("command") {
                flags.insert(.command)
            }
            if customShortcut.modifiers.contains("shift") {
                flags.insert(.shift)
            }
            if customShortcut.modifiers.contains("option") {
                flags.insert(.option)
            }
            if customShortcut.modifiers.contains("control") {
                flags.insert(.control)
            }
            return flags
        }()
        
        let key: KeyboardShortcuts.Key = {
            switch customShortcut.key.lowercased() {
            case "a": return .a
            case "b": return .b
            case "c": return .c
            case "d": return .d
            case "e": return .e
            case "f": return .f
            case "g": return .g
            case "h": return .h
            case "i": return .i
            case "j": return .j
            case "k": return .k
            case "l": return .l
            case "m": return .m
            case "n": return .n
            case "o": return .o
            case "p": return .p
            case "q": return .q
            case "r": return .r
            case "s": return .s
            case "t": return .t
            case "u": return .u
            case "v": return .v
            case "w": return .w
            case "x": return .x
            case "y": return .y
            case "z": return .z
            case "0": return .zero
            case "1": return .one
            case "2": return .two
            case "3": return .three
            case "4": return .four
            case "5": return .five
            case "6": return .six
            case "7": return .seven
            case "8": return .eight
            case "9": return .nine
            case ";": return .semicolon
            case "'": return .quote
            case ",": return .comma
            case ".": return .period
            case "/": return .slash
            case "\\": return .backslash
            case "-": return .minus
            case "=": return .equal
            case "[": return .leftBracket
            case "]": return .rightBracket
            case " ": return .space
            case "tab": return .tab
            case "return": return .return
            case "escape": return .escape
            case "delete": return .delete
            default: fatalError("Unsupported key: \(customShortcut.key)")
            }
        }()
                
        return Self(key, modifiers: modifiers)
    }
}
