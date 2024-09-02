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
        
    let persistenceController = PersistenceController.shared
    let userDefaultsManager = UserDefaultsManager.shared
    let clipboardManager = ClipboardManager.shared
    weak var menuManager: MenuManager?
    
    var contentView: ContentView!
    var finalView: AnyView!

    var window: NSWindow?
    var popover: NSPopover?
    
    private init() {}
    
    func setupApp() {
        self.menuManager?.setupStatusBar()
        
//        contentView = ContentView()
            
        self.finalView = AnyView(
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(clipboardManager)
                .environmentObject(self)
                .environmentObject(menuManager!)
        )
                        
        NSApplication.shared.mainMenu = nil
//        self.menuManager.setupMainMenu(isCopyingPaused: nil)
        self.menuManager?.updateMainMenu(isCopyingPaused: nil)
        
        
        
        if UserDefaultsManager.shared.windowPopOut {
            print("finished launching popping out")
            self.setupPopOutWindow()
        }
        else {
            print("window manager shouldnt be here")
            if let window = NSApplication.shared.windows.first {
                self.window = window
                self.setupWindow(window: window)
                
//                if UserDefaultsManager.shared.hideWindowWhenNotSelected {
//                    NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: nil)
//                }
            }
        }
        
    }
    
    func setupWindow(window: NSWindow) {
        print("setup reg window BAD")
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
    
    @objc func handleStatusItemPressed(_ sender: Any?) {
        if userDefaultsManager.windowPopOut {
            print("toggle: Status Item Popping out")
            togglePopOutWindow(sender)
        }
        else {
            print("toggle: showing window")
           showWindow()
        }
    }
    
    func handleResetWindow() {
        if userDefaultsManager.windowPopOut {
            print("reset: Status Item window reset")
            resetPopOutWindow()
        }
        else {
            print("reset: reset window")
           resetWindow()
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
            self.menuManager?.updateMainMenu(isCopyingPaused: nil)
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
    
    func setupPopOutWindow() {
        print("setup Pop Out window")
        
        if self.popover == nil {
            self.popover = NSPopover()
        }
                
        let hostingController = NSHostingController(rootView: self.finalView)
        let windowWidth: CGFloat = userDefaultsManager.windowWidth
        let windowHeight: CGFloat = userDefaultsManager.windowHeight
        hostingController.view.frame.size = CGSize(width: windowWidth, height: windowHeight)
        popover?.contentViewController = hostingController
        
        popover?.behavior = .transient // makes window close when you click outside of it
        
//        if let button = menuManager?.statusBarItem?.button {
            NSApp.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
        popover?.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
            
            self.menuManager?.updateMainMenu(isCopyingPaused: nil)
        
//            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
//        }
    }
    
    func togglePopOutWindow(_ sender: Any?) {
        let hostingController = NSHostingController(rootView: self.finalView)
        let windowWidth: CGFloat = userDefaultsManager.windowWidth
        let windowHeight: CGFloat = userDefaultsManager.windowHeight
        hostingController.view.frame.size = CGSize(width: windowWidth, height: windowHeight)
        popover?.contentViewController = hostingController
        popover?.contentSize = NSSize(width: windowWidth, height: windowHeight)
        
        popover?.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
        
        popover?.behavior = .transient // makes window close when you click outside of it
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        self.menuManager?.updateMainMenu(isCopyingPaused: nil)
        
        if let popover = popover {
            if popover.isShown {
                if let sender = sender {
                    popover.performClose(sender)
                }
                else {
                    popover.close()
                }
            } else {
                if let button = menuManager?.statusBarItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
    
    func hidePopOutWindow() {
        self.menuManager?.updateMainMenu(isCopyingPaused: nil)
        
        popover?.close()
    }
    
    func showPopOutWindow() {
        if let button = menuManager?.statusBarItem?.button {
            NSApp.appearance = NSAppearance(named: UserDefaults.standard.bool(forKey: "darkMode") ? .darkAqua : .vibrantLight)
            popover?.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
            
            self.menuManager?.updateMainMenu(isCopyingPaused: nil)
        
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func resetPopOutWindow() {
        let hostingController = NSHostingController(rootView: self.finalView)
//        let windowWidth: CGFloat = userDefaultsManager.windowWidth
        let windowWidth: CGFloat = CGFloat(UserDefaults.standard.float(forKey: "windowWidth"))

//        let windowHeight: CGFloat = userDefaultsManager.windowHeight
        let windowHeight: CGFloat = CGFloat(UserDefaults.standard.float(forKey: "windowHeight"))
        
        hostingController.view.frame.size = CGSize(width: windowWidth, height: windowHeight)
        popover?.contentViewController = hostingController
        
        popover?.contentSize = NSSize(width: windowWidth, height: windowHeight)
        
        popover?.behavior = .transient // makes window close when you click outside of it
        
        showPopOutWindow()
    }
}
