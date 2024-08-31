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
        NSApp.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
        
        self.window = window
        
        if let window = self.window {
            window.collectionBehavior = [] // No special behavior
            
            let screen = window.screen ?? NSScreen.main!
            let windowWidth: CGFloat = userDefaultsManager.windowWidth
            let windowHeight: CGFloat = userDefaultsManager.windowHeight
            
            
            var xPosition: CGFloat
            var yPosition: CGFloat
            switch userDefaultsManager.windowLocation {
            case "Bottom Right":
                xPosition = screen.visibleFrame.maxX - windowWidth
                yPosition = screen.visibleFrame.minY
                
            case "Bottom Left":
                xPosition = screen.visibleFrame.minX
                yPosition = screen.visibleFrame.minY
                
            case "Top Right":
                xPosition = screen.visibleFrame.maxX - windowWidth
                yPosition = screen.visibleFrame.maxY - windowHeight
                
            case "Top Left":
                xPosition = screen.visibleFrame.minX
                yPosition = screen.visibleFrame.maxY - windowHeight
                
            case "Center":
                xPosition = screen.visibleFrame.maxX/2 - windowWidth/2
                yPosition = screen.visibleFrame.maxY/2 - windowHeight/2
                
            default:
                // Default to BottomRight
                xPosition = screen.visibleFrame.maxX - windowWidth
                yPosition = screen.visibleFrame.minY
            }
            
            let frame = CGRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
            window.setFrame(frame, display: true)
//            if self.userDefaultsManager.canWindowFloat {
            if UserDefaultsManager.shared.canWindowFloat {
                window.level = .floating
            }
//            if userDefaultsManager.windowOnAllDesktops {
            if UserDefaultsManager.shared.windowOnAllDesktops {
                window.collectionBehavior = .canJoinAllSpaces
            }
            NSApplication.shared.activate(ignoringOtherApps: true)
                        
            
//                    window.standardWindowButton(.closeButton)?.isHidden = true
//                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
//                    window.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
    
    func resetWindow() {
        if let window = NSApplication.shared.windows.first {
            NSApp.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)

            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            let screen = window.screen ?? NSScreen.main!
            
            let windowWidth: CGFloat = userDefaultsManager.windowWidth
            let windowHeight: CGFloat = userDefaultsManager.windowHeight
            
            var xPosition: CGFloat
            var yPosition: CGFloat
            switch userDefaultsManager.windowLocation {
            case "Bottom Right":
                xPosition = screen.visibleFrame.maxX - windowWidth
                yPosition = screen.visibleFrame.minY
                
            case "Bottom Left":
                xPosition = screen.visibleFrame.minX
                yPosition = screen.visibleFrame.minY
                
            case "Top Right":
                xPosition = screen.visibleFrame.maxX - windowWidth
                yPosition = screen.visibleFrame.maxY - windowHeight
                
            case "Top Left":
                xPosition = screen.visibleFrame.minX
                yPosition = screen.visibleFrame.maxY - windowHeight
                
            case "Center":
                xPosition = screen.visibleFrame.maxX/2 - windowWidth/2
                yPosition = screen.visibleFrame.maxY/2 - windowHeight/2
                
            default:
                // Default to BottomRight
                print("default")
                xPosition = screen.visibleFrame.maxX - windowWidth
                yPosition = screen.visibleFrame.minY
            }
            
            let frame = CGRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
            window.setFrame(frame, display: true)
            
//            if self.userDefaultsManager.canWindowFloat {
            if UserDefaultsManager.shared.canWindowFloat {
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
//                    if self.userDefaultsManager.windowOnAllDesktops {
                    if UserDefaultsManager.shared.windowOnAllDesktops {
                        window.collectionBehavior = .canJoinAllSpaces
                    }
//                    if self.userDefaultsManager.canWindowFloat {
                    if UserDefaultsManager.shared.canWindowFloat {
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
//                if self.userDefaultsManager.windowOnAllDesktops {
                if UserDefaultsManager.shared.windowOnAllDesktops {
                    window.collectionBehavior = .canJoinAllSpaces
                }
//                if self.userDefaultsManager.canWindowFloat {
                if UserDefaultsManager.shared.canWindowFloat {
                    window.level = .floating
                }
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc func hideWindow() {
        DispatchQueue.main.async {
            NSApp.hide(nil)
        }
    }
}
