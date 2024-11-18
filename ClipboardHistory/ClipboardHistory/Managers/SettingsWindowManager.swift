//
//  SettingsWindowManager.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/30/24.
//

import Foundation
import AppKit
import Cocoa
import SwiftUI
import KeyboardShortcuts
import Combine


class SettingsWindowManager: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    
    //    let userDefaultsManager = UserDefaultsManager.shared
    //    let clipboardManager = ClipboardManager.shared
    //    weak var menuManager: MenuManager?
    
    var settingsWindow: NSWindow?
    @Published var isSettingsOpen = false
    
    private override init() {}
    
    func setupSettingsWindow() {
        if let settingsWindow = settingsWindow {
            settingsWindow.close()
            
        }
        self.settingsWindow = nil
        
        isSettingsOpen = true
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 1000),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false)
        
        let windowWidth: CGFloat = 500
        let windowHeight: CGFloat = 1000
        
        let xPosition = 0.0
        let yPosition = 0.0
        
        let frame = CGRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        settingsWindow?.setFrame(frame, display: true)
        
        
        settingsWindow?.title = "Settings" // Set the window title
        
        let settingsView = SettingsView()
        settingsWindow?.setFrameAutosaveName("SettingsWindow")
        settingsWindow?.contentView = NSHostingView(rootView: settingsView)
        
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)  // Make it the key window and bring to front
        NSApplication.shared.activate(ignoringOtherApps: true)  // Ensure the app is active

        //            settingsWindow?.standardWindowButton(.closeButton)?.isHidden = true
        settingsWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        settingsWindow?.standardWindowButton(.zoomButton)?.isHidden = true

        settingsWindow?.isReleasedWhenClosed = false  // Keep the window alive
        
        // **Set self as the delegate**
        settingsWindow?.delegate = self
    }
    
    func closeSettingsWindow() {
        if let settingsWindow = self.settingsWindow {
            settingsWindow.orderOut(nil)
            isSettingsOpen = false
        }
    }
    
    // MARK: - NSWindowDelegate Methods
        
    @objc func windowWillClose(_ notification: Notification) {
        // Detect when the user closes the settings window
        if let window = notification.object as? NSWindow, window == settingsWindow {
//            print("Settings window will close")
            isSettingsOpen = false
        }
    }
    
//    @objc func windowShouldClose(_ sender: NSWindow) -> Bool {
//        // Optionally, decide whether the window should close
//        if sender == settingsWindow {
//            print("Settings window close button clicked")
//            return true // Allow the window to close
//        }
//        return true
//    }
}
