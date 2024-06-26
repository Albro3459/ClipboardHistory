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
        self.clipboardMonitor = ClipboardMonitor()
        self.clipboardMonitor?.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//                .toolbar {
//                    ToolbarItem(placement: .automatic) {
//                        SearchBarView()
//                    }
//                }
        }
        
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusBarItem: NSStatusItem?
    
    private var lastToggleTime: Date?
    private var lastPasteNoFormatTime: Date?
    
    override init() {
        super.init()
        setupGlobalHotKey()
    }
    
    func setupGlobalHotKey() {
        KeyboardShortcuts.onKeyDown(for: .toggleVisibility) {
            self.toggleWindowVisibility()
        }
        
        KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
            self.pasteNoFormatting()
        }
    }
    
    @objc func toggleWindowVisibility() {
        //        print("Cmd-Shift-C pressed: Toggling window visibility")
        
        let now = Date()
        if let lastToggleTime = lastToggleTime, now.timeIntervalSince(lastToggleTime) < 0.33 {
            //            print("Toggle too fast, ignoring.")
            return
        }
        self.lastToggleTime = now
        
        DispatchQueue.main.async {
            if let window = self.window {
                if !window.isKeyWindow {
                    window.makeKeyAndOrderFront(nil)
                    window.collectionBehavior = .canJoinAllSpaces
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                else {
                    window.orderOut(nil)
                }
            }
        }
    }
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupGlobalHotKey()
        
        if let window = NSApplication.shared.windows.first {
            let screen = window.screen ?? NSScreen.main!
            let windowWidth: CGFloat = 300
            let windowHeight: CGFloat = 500
            
            let xPosition = screen.visibleFrame.maxX - windowWidth
            let yPosition = screen.visibleFrame.minY
            
            let frame = CGRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
            window.setFrame(frame, display: true)
            //            window.level = .floating
            window.collectionBehavior = .canJoinAllSpaces
            self.window = window
        }
        
        setupStatusBar()
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
            button.action = #selector(toggleWindowVisibility)
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
    
}

extension KeyboardShortcuts.Name {
    static var toggleVisibility = Self("toggleVisibility", default: .init(.c, modifiers: [.command, .shift]))
    static var pasteNoFormatting = Self("pasteNoFormatting", default: .init(.v, modifiers: [.command, .shift]))
}
