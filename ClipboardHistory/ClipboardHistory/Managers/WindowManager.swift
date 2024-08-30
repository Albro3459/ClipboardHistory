//
//  WindowManager.swift
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


class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    let userDefaultsManager = UserDefaultsManager.shared
    let clipboardManager = ClipboardManager.shared
    weak var menuManager: MenuManager?
    
    var window: NSWindow?
    
    private init() {}
    
    func setupWindow(window: NSWindow) {
        self.window = window
        
        if let window = self.window {
            window.collectionBehavior = [] // No special behavior
            
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
            
            self.menuManager?.updateMainMenu(isCopyingPaused: nil)
        }
    }
    
    @objc func toggleWindow() {
        //                print("Cmd-Shift-C pressed: Toggling window visibility")
        
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
                    self.menuManager?.updateMainMenu(isCopyingPaused: nil)
                }
                else {
                    self.hideWindow()
                }
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
    
    @objc func hideWindow() {
        DispatchQueue.main.async {
//            if let window = self.window {
//                window.orderOut(nil)
////                window.miniaturize(nil)
//            }
            NSApp.hide(nil)
        }
    }
    
    @objc func windowDidResignKey(_ notification: Notification) {
//        print("Window did resign key (unfocused)")
        // App lost focus
        
        if userDefaultsManager.hideWindowWhenNotSelected {
            self.hideWindow()
        }
    }
    
}
