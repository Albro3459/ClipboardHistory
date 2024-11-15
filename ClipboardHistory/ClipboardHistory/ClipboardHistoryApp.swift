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
            "windowPopOut": false,
            "canWindowFloat": false,
            "hideWindowWhenNotSelected": false,
            "windowOnAllDesktops": true,
            
            "pauseCopying": false,
            
            "maxStoreCount": 50,
            "noDuplicates": true,
            "canCopyFilesOrFolders": true,
            "canCopyImages": true,
            
            "enterKeyHidesAfterCopy" : false,
            "pasteWithoutFormatting": false,
            "pasteLowercaseWithoutFormatting": false,
            "pasteUppercaseWithoutFormatting": false,
            
            // out of app shortcuts
            "pasteWithoutFormattingShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["command", "shift"], key: "v")),
            "pasteLowercaseWithoutFormattingShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["option", "shift"], key: "l")),
            "pasteUppercaseWithoutFormattingShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["option", "shift"], key: "u")),
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
    let clipboardManager: ClipboardManager?
    
    let userDefaultsManager: UserDefaultsManager?
    let windowManager: WindowManager?
    let menuManager: MenuManager?
    let viewStateManager: ViewStateManager?

    
    
    private var lastToggleTime: Date?
    private var lastPasteNoFormatTime: Date?
            
    override init() {
        self.persistenceController = PersistenceController.shared
        self.clipboardManager = ClipboardManager.shared

        self.userDefaultsManager = UserDefaultsManager.shared
        self.windowManager = WindowManager.shared
        self.menuManager = MenuManager.shared
        self.viewStateManager = ViewStateManager.shared
        
        super.init()
        
        self.clipboardManager?.clipboardMonitor?.windowManager = self.windowManager
        self.windowManager?.clipboardManager = self.clipboardManager
        
        self.windowManager?.menuManager = self.menuManager
        self.menuManager?.windowManager = self.windowManager
                
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
            self.windowManager?.handleToggleWindow()
        }
        
        KeyboardShortcuts.onKeyUp(for: .resetWindow) {
            self.windowManager?.handleResetWindow()
        }
        
        KeyboardShortcuts.onKeyDown(for: .hideWindow) {
//            if UserDefaultsManager.shared.windowPopOut {
//                self.windowManager?.hidePopOutWindow()
//            }
//            else {
                self.windowManager?.hideWindow()
//            }
        }
        
        if let userDefaultsManager = self.userDefaultsManager, userDefaultsManager.pasteWithoutFormatting {
            KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                self.clipboardManager?.pasteNoFormatting(lowerFalseUpperTrueText: nil)
            }
        }
        else { // otherwise free it up, so I dont consume the keystroke
            KeyboardShortcuts.disable(.pasteNoFormatting)
        }
        
        if let userDefaultsManager = self.userDefaultsManager, userDefaultsManager.pasteLowercaseWithoutFormatting {
            KeyboardShortcuts.onKeyUp(for: .pasteLowerNoFormatting) {
                self.clipboardManager?.pasteNoFormatting(lowerFalseUpperTrueText: false)
            }
        }
        else { // otherwise free it up, so I dont consume the keystroke
            KeyboardShortcuts.disable(.pasteLowerNoFormatting)
        }
        
        if let userDefaultsManager = self.userDefaultsManager, userDefaultsManager.pasteUppercaseWithoutFormatting {
            KeyboardShortcuts.onKeyUp(for: .pasteUpperNoFormatting) {
                self.clipboardManager?.pasteNoFormatting(lowerFalseUpperTrueText: true)
            }
        }
        else { // otherwise free it up, so I dont consume the keystroke
            KeyboardShortcuts.disable(.pasteUpperNoFormatting)
        }
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
//        setupGlobalHotKey()
        
        self.windowManager?.setupApp()
    
        
//        if !UserDefaultsManager.shared.windowPopOut && UserDefaultsManager.shared.hideWindowWhenNotSelected {
//            windowManager?.addObserverForWindowFocus()
//        }
        
        self.windowManager?.appDelegate = self
        self.windowManager?.window?.delegate = self
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//        print("Dock icon clicked!")
        
        menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
        
        if UserDefaultsManager.shared.windowPopOut {
            windowManager?.window = nil
            if windowManager?.popover == nil {
                windowManager?.setupPopOutWindow()
            }
            else {
                windowManager?.showPopOutWindow()
            }
        }
        else {
            if windowManager?.window == nil {
                windowManager?.setupWindow()
            }
            else {
                windowManager?.showWindow()
            }
        }
        
        return true
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.windowManager?.hideApp()
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Remove all observers
        NotificationCenter.default.removeObserver(self)
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
    
    static var pasteLowerNoFormatting: Self {
        let userDefaultsManager = UserDefaultsManager.shared
        return Self("pasteLowerNoFormatting", default: .from(userDefaultsManager.pasteLowercaseWithoutFormattingShortcut))
    }
    
    static var pasteUpperNoFormatting: Self {
        let userDefaultsManager = UserDefaultsManager.shared
        return Self("pasteUpperNoFormatting", default: .from(userDefaultsManager.pasteUppercaseWithoutFormattingShortcut))
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
