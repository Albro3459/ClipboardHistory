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


class SettingsWindowManager: ObservableObject {
    static let shared = SettingsWindowManager()
    
    //    let userDefaultsManager = UserDefaultsManager.shared
    //    let clipboardManager = ClipboardManager.shared
    //    weak var menuManager: MenuManager?
    
    var settingsWindow: NSWindow?
    
    private init() {}
    
    func setupSettingsWindow() {
        if settingsWindow == nil {
            
            settingsWindow = NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 500, height: 1000),
                            styleMask: [.titled, .closable, .resizable],
                            backing: .buffered, defer: false)
            
//            settingsWindow = NSWindow()
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
            settingsWindow?.orderFrontRegardless()
            
//            settingsWindow?.standardWindowButton(.closeButton)?.isHidden = true
            settingsWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
            settingsWindow?.standardWindowButton(.zoomButton)?.isHidden = true
            
            settingsWindow?.isReleasedWhenClosed = false // Keep the window alive
            
            
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
