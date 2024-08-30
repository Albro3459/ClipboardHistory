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
    
    let userDefaultsManager = UserDefaultsManager.shared
    let clipboardManager = ClipboardManager.shared
    weak var windowManager: WindowManager?
    
    var statusBarItem: NSStatusItem?
    
    var appMenu: NSMenu?
        
    private init() { }
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            
            if let image = NSImage(named: NSImage.Name("AppIcon")) {
                image.isTemplate = true
                button.image = resizeImage(image: image, width: 16, height: 16)
            } else {
                button.title = userDefaultsManager.appName
            }
            button.action = #selector(windowManager?.showWindow)
            button.target = windowManager
            
        } else {
            print("Failed to create status bar item")
        }
    }
    
    func setupMainMenu(isCopyingPaused: Bool?) {
        let appMenu = NSMenu()
        
        // First App Menu
        let mainMenu = NSMenu()
        let githubItem = NSMenuItem(title: "GitHub", action: #selector(openGitHub), keyEquivalent: ";")
        githubItem.target = self
        mainMenu.addItem(githubItem)
        
        let linkedinItem = NSMenuItem(title: "Creator's LinkedIn", action: #selector(openLinkedIn), keyEquivalent: "'")
        linkedinItem.target = self
        mainMenu.addItem(linkedinItem)
        
        mainMenu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(title: "\(userDefaultsManager.appName) Settings...", action: #selector(openSettings), keyEquivalent: ",")
        preferencesItem.target = self
        mainMenu.addItem(preferencesItem)
        
        let quitItem = NSMenuItem(title: "Quit \(userDefaultsManager.appName)", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        mainMenu.addItem(quitItem)
        
        let appMenuTitle = NSMenuItem(title: "ClipboardManager", action: nil, keyEquivalent: "")
        appMenuTitle.submenu = mainMenu
        appMenu.addItem(appMenuTitle)
        
        
        // File Menu
        let fileMenu = NSMenu(title: "File")
        let pauseResumeItem = NSMenuItem(title: (isCopyingPaused ?? userDefaultsManager.pauseCopying ? "Resume Copying" : "Pause Copying"), action: #selector(toggleCopying), keyEquivalent: "P")
        pauseResumeItem.keyEquivalentModifierMask = [.command, .shift]
        pauseResumeItem.target = self
        fileMenu.addItem(pauseResumeItem)
        
        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu
        
        appMenu.addItem(fileMenuItem)
        
        
        // Window Menu
        let windowMenu = NSMenu(title: "Window")
        let toggleWindowItem = NSMenuItem(title: "Show/Hide App", action: #selector(windowManager?.toggleWindow), keyEquivalent: userDefaultsManager.toggleWindowShortcut.toKeyEquivalent() ?? "C")
        toggleWindowItem.keyEquivalentModifierMask = userDefaultsManager.toggleWindowShortcut.toModifierFlags()
        toggleWindowItem.target = WindowManager.shared
        windowMenu.addItem(toggleWindowItem)
        
        // keyEquivalent of capital letter tells swift to add Shift to the command!!
        let hideItem = NSMenuItem(title: "Hide App", action: #selector(windowManager?.hideWindow), keyEquivalent: "h")
        hideItem.target = WindowManager.shared
        windowMenu.addItem(hideItem)
        
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = windowMenu
        
        appMenu.addItem(windowMenuItem)
        
        
        
        // Help Menu
        let helpMenu = NSMenu(title: "Help")
        let helpMenuItem = NSMenuItem()
        helpMenu.addItem(NSMenuItem(title: "List of Keyboard Shortcuts", action: nil, keyEquivalent: "/"))
        helpMenuItem.submenu = helpMenu
        appMenu.addItem(helpMenuItem)
        
        
        // Set the main menu
        NSApp.mainMenu = appMenu
        self.appMenu = appMenu
    }
    
    func updateMainMenu(isCopyingPaused: Bool?) {
        let isCopyingPaused = isCopyingPaused ?? UserDefaults.standard.bool(forKey: "pauseCopying")
        if let appMenu = self.appMenu {
            // updates when isCopyingPaused changes
            if let fileMenu = appMenu.item(at: 2), let fileSubmenu = fileMenu.submenu, let fileItem = fileSubmenu.items.first {
                fileItem.title = isCopyingPaused  ? "Resume Copying" : "Pause Copying"
            }
            else {
                
            }
        }
        else {
            self.setupMainMenu(isCopyingPaused: isCopyingPaused)
        }
    }

    
    @objc func toggleCopying() {
        // Flip the current pause state
        DispatchQueue.main.async {

            print("toggling copying")
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
            
            self.updateMainMenu(isCopyingPaused: newIsCopyingPausedState)
            
            self.clipboardManager.clipboardMonitor?.sendCopyStatusCangeStateChangeToUI()
        }
    }
    
    @objc func openGitHub() {
        // Code to open the github window
        if let url = URL(string: "https://www.github.com/albro3459/ClipboardHistory") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func openLinkedIn() {
        // Code to open the linkedin window
        if let url = URL(string: "https://www.linkedin.com/in/brodsky-alex22/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func openSettings() {
        // Code to open the settings window
        print("open settings")
    }
    
    // UPDATE ME!!
    @objc func openClipboardShortcutsLink() {
        // Code to open the linkedin window
        if let url = URL(string: "https://github.com/Albro3459/ClipboardHistory/blob/main/ListOfKeyboardShortcuts.md") {
            NSWorkspace.shared.open(url)
        }
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
