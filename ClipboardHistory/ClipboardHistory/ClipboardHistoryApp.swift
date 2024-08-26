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
    var clipboardMonitor: ClipboardMonitor?
        
    @State private var hideTitle = false
    
    init() {
        //have to register first!!
        self.registerUserDefaults()

        
        self.clipboardMonitor = ClipboardMonitor()
        self.clipboardMonitor?.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appDelegate.clipboardManager)
        }
        
    }
    
    private func registerUserDefaults() {
        // User Defaults
        
        let encoder = JSONEncoder()
        
        let defaults: [String: Any] = [
            "darkMode": true, // TODO
            "openOnStartup": true, // TODO
            
            "windowWidth": 300,
            "windowHeight": 500,
            "windowLocation": "bottomRight", // TODO
            "windowPopOut": false, // TODO
            "onlyPopOutWindow": false, // TODO
            "canWindowFloat": false,
            "hideWindowWhenNotSelected": false,
            "windowOnAllDesktops": true,
            
            "showMenuIcon": true, // TODO ehh idk i think it should stay there
            "pauseCopying": false, // TODO
            
            "maxStoreCount": 50,
            "noDuplicates": true,
            "canCopyFilesOrFolders": true,
            "canCopyImages": true,
            
            "pasteWithoutFormatting": true,
            
            // out of app shortcuts
            "pasteWithoutFormattingShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd", "shift"], key: "v")),
            "toggleWindowShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd", "shift"], key: "c")),
            "resetWindowShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["option"], key: "r")),
            
            //in-app shortcuts
            "openSearchShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd"], key: "f")), // TODO
            "deleteSelectedItemShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd"], key: "d")), // TODO
            "scrollUpShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd"], key: "upArrow")), // TODO
            "scrollDownShortcut": try! encoder.encode(KeyboardShortcut(modifiers: ["cmd"], key: "downArrow")) // TODO
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var statusBarItem: NSStatusItem?
    
    var clipboardManager = ClipboardManager()
    let userDefaultsManager = UserDefaultsManager.shared
    
    private var lastToggleTime: Date?
    private var lastPasteNoFormatTime: Date?
    
    
    override init() {
        super.init()
        setupGlobalHotKey()
    }

    func setupGlobalHotKey() {
        KeyboardShortcuts.onKeyDown(for: .toggleWindow) {
            self.toggleWindow()
        }
        
        if userDefaultsManager.pasteWithoutFormatting {
            KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                self.pasteNoFormatting()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .resetWindow) {
            self.resetWindow()
        }
        
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        setupGlobalHotKey()
        
        if let window = NSApplication.shared.windows.first {
            setupWindow(window: window)
                   
            self.window = window
            
            window.collectionBehavior = [] // No special behavior
            
//            NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeKey(_:)), name: NSWindow.didBecomeKeyNotification, object: nil)
            if userDefaultsManager.hideWindowWhenNotSelected {
                NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: nil)
            }
        }
        
        setupStatusBar()
    }
    
    @objc func toggleWindow() {
//                print("Cmd-Shift-C pressed: Toggling window visibility")
                
        let now = Date()
        if let lastToggleTime = lastToggleTime, now.timeIntervalSince(lastToggleTime) < 0.33 {
            //            print("Toggle too fast, ignoring.")
            return
        }
        self.lastToggleTime = now
        
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = self.window {
                if !window.isKeyWindow {
                    window.makeKeyAndOrderFront(nil)
                    if self.userDefaultsManager.windowOnAllDesktops {
                        window.collectionBehavior = .canJoinAllSpaces
                    }
                    if self.userDefaultsManager.canWindowFloat {
                        window.level = .floating
                    }
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                else {
                    window.orderOut(nil)
                }
            }
        }
    }
    
    @objc func windowDidResignKey(_ notification: Notification) {
//        print("Window did resign key (unfocused)")
        // App lost focus
        
        if userDefaultsManager.hideWindowWhenNotSelected {
            hideWindow()
        }
    }
    
    @objc func hideWindow() {
        DispatchQueue.main.async {
            if let window = self.window {
                window.orderOut(nil)
            }
        }
    }
    
    func setupWindow(window: NSWindow) {
        let screen = window.screen ?? NSScreen.main!
        let windowWidth: CGFloat = userDefaultsManager.windowWidth
        let windowHeight: CGFloat = userDefaultsManager.windowHeight
                                
        let xPosition = screen.visibleFrame.maxX - windowWidth
        let yPosition = screen.visibleFrame.minY
        
        let frame = CGRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        window.setFrame(frame, display: true)
        if self.userDefaultsManager.canWindowFloat {
            window.level = .floating
        }
        if userDefaultsManager.windowOnAllDesktops {
            window.collectionBehavior = .canJoinAllSpaces
        }
        NSApplication.shared.activate(ignoringOtherApps: true)

        
//        window.standardWindowButton(.closeButton)?.isHidden = true
//        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
//        window.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    func resetWindow() {
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            let screen = window.screen ?? NSScreen.main!

            let windowWidth: CGFloat = userDefaultsManager.windowWidth
            let windowHeight: CGFloat = userDefaultsManager.windowHeight
            
            let xPosition = screen.visibleFrame.maxX - windowWidth
            let yPosition = screen.visibleFrame.minY
            
            let frame = CGRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
            window.setFrame(frame, display: true)
            
            if self.userDefaultsManager.canWindowFloat {
                window.level = .floating
            }
        }
    }
    
    @objc func showWindow() {
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = self.window {
                window.makeKeyAndOrderFront(nil)
                if self.userDefaultsManager.windowOnAllDesktops {
                    window.collectionBehavior = .canJoinAllSpaces
                }
                if self.userDefaultsManager.canWindowFloat {
                    window.level = .floating
                }
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
    
    
    public func pasteNoFormatting() {
        let pasteboard = NSPasteboard.general
        
        // Check for file URLs first
        if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let _ = fileUrls.first {
        } else if let imageData = pasteboard.data(forType: .tiff), let _ = NSImage(data: imageData) {
        } else if let content = pasteboard.string(forType: .string) {
            updatePasteboard(with: content)
        }
        
        paste()
    }
    
    private func updatePasteboard(with plainText: String) {
        let pasteboard = NSPasteboard.general
        
        pasteboard.clearContents()
        pasteboard.setString(plainText, forType: .string)
        paste()
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
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            
            if let image = NSImage(named: NSImage.Name("AppIcon")) {
                image.isTemplate = true
                button.image = resizeImage(image: image, width: 16, height: 16)
            } else {
                button.title = "ClipboardHistory"
            }
            button.action = #selector(showWindow)
            button.target = self
            //            print("Status bar item set up")
        } else {
            //            print("Failed to create status bar item")
        }
        
    }
    
    func resizeImage(image: NSImage, width: CGFloat, height: CGFloat) -> NSImage {
        let newSize = NSMakeSize(width, height)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        newImage.isTemplate = image.isTemplate
        return newImage
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Remove observers
//        NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: nil)
        if userDefaultsManager.hideWindowWhenNotSelected {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didResignKeyNotification, object: nil)
        }
    }
}

extension KeyboardShortcuts.Name {
    static var toggleWindow: Self {
        let userDefaultsManager = UserDefaultsManager.shared
        return Self("toggleWindow", default: .from(userDefaultsManager.toggleWindowShortcut))
    }

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


class UserDefaultsManager {
    static let shared = UserDefaultsManager()

//  User Defaults
    var darkMode: Bool
    var openOnStartup: Bool
    
    var windowWidth: CGFloat
    var windowHeight: CGFloat
    var windowLocation: String
    var windowPopOut: Bool  // pop out of the menu button when clicked
    var canWindowFloat: Bool
    var hideWindowWhenNotSelected: Bool
    var windowOnAllDesktops: Bool
    
    var showMenuIcon: Bool
    var pauseCopying: Bool
    
    var noDuplicates: Bool
    var maxStoreCount: Int
    var canCopyFilesOrFolders: Bool
    var canCopyImages: Bool
    
    var pasteWithoutFormatting: Bool
    
    var pasteWithoutFormattingShortcut: KeyboardShortcut
    var toggleWindowShortcut: KeyboardShortcut
    var resetWindowShortcut: KeyboardShortcut
    var openSearchShortcut: KeyboardShortcut
    var deleteSelectedItemShortcut: KeyboardShortcut
    var scrollUpShortcut: KeyboardShortcut
    var scrollDownShortcut: KeyboardShortcut
    
    init() {
        let decoder = JSONDecoder()
        
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.openOnStartup = UserDefaults.standard.bool(forKey: "openOnStartup")
        
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

        self.showMenuIcon = UserDefaults.standard.bool(forKey: "showMenuIcon")
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
        
        if let data = UserDefaults.standard.data(forKey: "openSearchShortcut") {
            self.openSearchShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            self.openSearchShortcut = KeyboardShortcut(modifiers: ["cmd"], key: "f")
        }
        
        if let data = UserDefaults.standard.data(forKey: "deleteSelectedItemShortcut") {
            self.deleteSelectedItemShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            self.deleteSelectedItemShortcut = KeyboardShortcut(modifiers: ["cmd"], key: "d")
        }
        
        if let data = UserDefaults.standard.data(forKey: "scrollUpShortcut") {
            self.scrollUpShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            self.scrollUpShortcut = KeyboardShortcut(modifiers: ["cmd"], key: "upArrow")
        }
        
        if let data = UserDefaults.standard.data(forKey: "scrollDownShortcut") {
            self.scrollDownShortcut = try! decoder.decode(KeyboardShortcut.self, from: data)
        } else {
            self.scrollDownShortcut = KeyboardShortcut(modifiers: ["cmd"], key: "downArrow")
        }
    }
}
