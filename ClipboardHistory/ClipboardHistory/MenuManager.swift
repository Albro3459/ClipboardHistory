//
//  MenuManager.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/27/24.
//

import Foundation
import AppKit
import Cocoa
import SwiftUI
import KeyboardShortcuts
import Combine


class MenuManager: ObservableObject {
    static let shared = MenuManager()
    
    let windowManager = WindowManager.shared
    let userDefaultsManager = UserDefaultsManager.shared
    let clipboardManager = ClipboardManager.shared
    
    var statusBarItem: NSStatusItem?
    
    private init() {}
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            
            if let image = NSImage(named: NSImage.Name("AppIcon")) {
                image.isTemplate = true
                button.image = resizeImage(image: image, width: 16, height: 16)
            } else {
                button.title = "ClipboardHistory"
            }
            button.action = #selector(windowManager.showWindow)
            button.target = self
                        
            self.setupMenu(statusBarItem: self.statusBarItem!)
            
        } else {
            print("Failed to create status bar item")
        }
    }
    
    private func setupMenu(statusBarItem: NSStatusItem) {
        let menu = NSMenu()
        
        let toggleWindowItem = NSMenuItem(title: "Show/Hide App", action: #selector(windowManager.toggleWindow), keyEquivalent: userDefaultsManager.toggleWindowShortcut.toKeyEquivalent() ?? "")
        toggleWindowItem.keyEquivalentModifierMask = userDefaultsManager.toggleWindowShortcut.toModifierFlags()
        toggleWindowItem.target = WindowManager.shared
        menu.addItem(toggleWindowItem)
        
        let pauseResumeItem = NSMenuItem(title: (userDefaultsManager.pauseCopying ? "Resume Copying" : "Pause Copying"), action: #selector(toggleCopying), keyEquivalent: "p")
        pauseResumeItem.keyEquivalentModifierMask = [.command, .shift]
        pauseResumeItem.target = self
        menu.addItem(pauseResumeItem)
        
        menu.addItem(NSMenuItem.separator())
        let aboutItem = NSMenuItem(title: "About...", action: #selector(openAbout), keyEquivalent: ".")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        let quitItem = NSMenuItem(title: "Quit ClipboardHistory", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
        
//        statusBarItem.isEnabled = true
    }
    
    private func updateMenu(isCopyingPaused: Bool) {
        if let statusBarItem = self.statusBarItem, let menu = statusBarItem.menu {
            
            menu.removeAllItems()
            
            let toggleWindowItem = NSMenuItem(title: "Show/Hide App", action: #selector(windowManager.toggleWindow), keyEquivalent: userDefaultsManager.toggleWindowShortcut.toKeyEquivalent() ?? "")
            toggleWindowItem.keyEquivalentModifierMask = userDefaultsManager.toggleWindowShortcut.toModifierFlags()
            toggleWindowItem.target = WindowManager.shared
            menu.addItem(toggleWindowItem)
            
            let pauseResumeItem = NSMenuItem(title: (isCopyingPaused ? "Resume Copying" : "Pause Copying"), action: #selector(toggleCopying), keyEquivalent: "p")
            pauseResumeItem.keyEquivalentModifierMask = [.command, .shift]
            pauseResumeItem.target = self
            menu.addItem(pauseResumeItem)
            
            menu.addItem(NSMenuItem.separator())
            let aboutItem = NSMenuItem(title: "About...", action: #selector(openAbout), keyEquivalent: ".")
            aboutItem.target = self
            menu.addItem(aboutItem)
            
            let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
            preferencesItem.target = self
            menu.addItem(preferencesItem)
            
            let quitItem = NSMenuItem(title: "Quit ClipboardHistory", action: #selector(quitApp), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)
        }
        
    }
    
    @objc func toggleCopying() {
        // Flip the current pause state
        DispatchQueue.main.async {

//            print("toggling copying")
            let isCopyingCurrentlyPausedState = UserDefaults.standard.bool(forKey: "pauseCopying")
                    
            let newIsCopyingPausedState = !isCopyingCurrentlyPausedState
            
            UserDefaults.standard.set(newIsCopyingPausedState, forKey: "pauseCopying")
            UserDefaults.standard.synchronize()
            
//             clear the clipboard when resuming because it will immediately copy what's in the clipboard
            if !newIsCopyingPausedState {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
            }
            
            self.clipboardManager.clipboardMonitor?.isCopyingPaused = newIsCopyingPausedState
            
            self.updateMenu(isCopyingPaused: newIsCopyingPausedState)
            
            self.clipboardManager.clipboardMonitor?.sendCopyStatusCangeStateChangeToUI()
        }
    }
    
    @objc private func openAbout() {
        // Code to open the preferences window
    }
    
    @objc private func openPreferences() {
        // Code to open the preferences window
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
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
