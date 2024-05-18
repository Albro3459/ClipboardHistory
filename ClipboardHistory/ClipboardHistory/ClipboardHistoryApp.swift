//
//  ClipboardHistoryApp.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import Cocoa
import SwiftUI
import KeyboardShortcuts


@main
struct ClipboardHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    var clipboardMonitor: ClipboardMonitor?

    init() {
        self.clipboardMonitor = ClipboardMonitor()
        self.clipboardMonitor?.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        //        .commands {
        //            SidebarCommands()
        //        }
        //        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    private var lastToggleTime: Date?
    
    override init() {
        super.init()
        setupGlobalHotKey()
    }
    
    func setupGlobalHotKey() {
        KeyboardShortcuts.onKeyDown(for: .toggleVisibility) {
            self.toggleWindowVisibility()
        }
    }
    
    
    func toggleWindowVisibility() {
        //        print("Cmd-Shift-C pressed: Toggling window visibility")
        
        let now = Date()
        if let lastToggleTime = lastToggleTime, now.timeIntervalSince(lastToggleTime) < 0.33 {
            //            print("Toggle too fast, ignoring.")
            return
        }
        self.lastToggleTime = now
        
        DispatchQueue.main.async {
            if let window = self.window {
                if !window.isVisible {
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
            window.level = .floating
            window.collectionBehavior = .canJoinAllSpaces
            self.window = window
        }
    }
}

extension KeyboardShortcuts.Name {
    static var toggleVisibility = Self("toggleVisibility", default: .init(.c, modifiers: [.command, .shift]))
}
