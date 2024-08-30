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
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appDelegate.clipboardManager)
                .environmentObject(appDelegate.windowManager)
                .environmentObject(appDelegate.menuManager)
        }
    }
    
    private func registerUserDefaults() {
        // User Defaults
        
        let encoder = JSONEncoder()
        
        let defaults: [String: Any] = [
            "appName": "ClipboardHistory",
            
            "darkMode": true, // TODO
            "windowWidth": 300,
            "windowHeight": 500,
            "windowLocation": "bottomRight", // TODO
            "windowPopOut": false, // TODO
            "onlyPopOutWindow": false, // TODO
            "canWindowFloat": false,
            "hideWindowWhenNotSelected": false,
            "windowOnAllDesktops": true,
            
            "pauseCopying": false,
            
            "maxStoreCount": 50,
            "noDuplicates": true,
            "canCopyFilesOrFolders": true,
            "canCopyImages": true,
            
            "pasteWithoutFormatting": true,
            
            // out of app shortcuts
            "pasteWithoutFormattingShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd", "shift"], key: "v")),
            "toggleWindowShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd", "shift"], key: "c")),
            "resetWindowShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["option"], key: "r")),
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var statusBarItem: NSStatusItem?
    
    let userDefaultsManager: UserDefaultsManager?
//    let windowManager: WindowManager?
//    let menuManager: MenuManager?
    let menuManager = MenuManager.shared
    let windowManager = WindowManager.shared

    
    let clipboardManager = ClipboardManager.shared
    
    private var lastToggleTime: Date?
    private var lastPasteNoFormatTime: Date?
            
    override init() {
        self.userDefaultsManager = UserDefaultsManager.shared
        
//        self.windowManager = WindowManager.shared
//        self.menuManager = MenuManager.shared
        self.menuManager.windowManager = self.windowManager
        self.windowManager.menuManager = self.menuManager
        
        super.init()
        setupGlobalHotKey()
    }

    func setupGlobalHotKey() {
        
        let now = Date()
        if let lastToggleTime = lastToggleTime, now.timeIntervalSince(lastToggleTime) < 0.33 {
//                        print("Toggle too fast, ignoring.")
            return
        }
        self.lastToggleTime = now
        
        
        KeyboardShortcuts.onKeyDown(for: .toggleWindow) {
            self.windowManager.toggleWindow()
        }
        
        KeyboardShortcuts.onKeyDown(for: .hideWindow) {
            self.windowManager.hideWindow()
        }
        
        if let userDefaultsManager = userDefaultsManager, userDefaultsManager.pasteWithoutFormatting {
            KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                self.pasteNoFormatting()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .resetWindow) {
            self.windowManager.resetWindow()
        }
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
                
        setupGlobalHotKey()
        
        if let window = NSApplication.shared.windows.first {
            self.windowManager.setupWindow(window: window)
            
                   
            
//            NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeKey(_:)), name: NSWindow.didBecomeKeyNotification, object: nil)
            if let userDefaultsManager = userDefaultsManager, userDefaultsManager.hideWindowWhenNotSelected {
                NotificationCenter.default.addObserver(self, selector: #selector(windowManager.windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: nil)
            }
        }
        
        self.menuManager.setupStatusBar()
        self.menuManager.setupMainMenu(isCopyingPaused: nil)

    }
    
    public func pasteNoFormatting() {
        
        DispatchQueue.main.async {

            self.clipboardManager.clipboardMonitor?.isPasteNoFormattingCopy = true
            
            let pasteboard = NSPasteboard.general
            
            // Check for file URLs first
            if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let _ = fileUrls.first {
            }
            else if let imageData = pasteboard.data(forType: .tiff), let _ = NSImage(data: imageData) {
            }
            else if let content = pasteboard.string(forType: .string) {
                self.updatePasteboard(with: content)
            } else if let rtfData = pasteboard.data(forType: .rtf) {
                // Convert RTF to plain text
                if let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                    let plainText = attributedString.string
                    self.updatePasteboard(with: plainText)
                }
            } else if let htmlData = pasteboard.data(forType: .html) {
                // Convert HTML to plain text
                if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                    let plainText = attributedString.string
                    self.updatePasteboard(with: plainText)
                }
            }
            
            self.paste()
        }
    }
    
    private func updatePasteboard(with plainText: String) {
        
        let pasteboard = NSPasteboard.general
        
        pasteboard.clearContents()
        pasteboard.setString(plainText, forType: .string)
        self.paste()
    }
    
    func paste() {
        let now = Date()
        if let lastPasteNoFormatTime = lastPasteNoFormatTime, now.timeIntervalSince(lastPasteNoFormatTime) < 0.33 {
            return
        }
        self.lastPasteNoFormatTime = now
        
        
        DispatchQueue.main.async {
            
            let cmdFlag = CGEventFlags.maskCommand
            let vCode: CGKeyCode = 9 // Key code for 'V' on a QWERTY keyboard
            
            let source = CGEventSource(stateID: .combinedSessionState)
            source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents], state: .eventSuppressionStateSuppressionInterval)
            
            let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true)
            let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false)
            keyVDown?.flags = cmdFlag
            keyVUp?.flags = cmdFlag
            keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
            
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
            if customShortcut.modifiers.contains("cmd") {
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
