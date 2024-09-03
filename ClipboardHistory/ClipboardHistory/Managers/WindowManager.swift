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
    
    var contentView: AnyView!

    var window: NSWindow?
    var popover: NSPopover?
    
    //#colorLiteral(red: 0.1882, green: 0.1882, blue: 0.1961, alpha: 0.75)
    let darkModeBackground = #colorLiteral(red: 0.1882, green: 0.1882, blue: 0.1961, alpha: 0.75)
    
    //#colorLiteral(red: 0.941, green: 0.937, blue: 0.941, alpha: 0.4)
    let lightModeBackground = #colorLiteral(red: 0.941, green: 0.937, blue: 0.941, alpha: 0.4)
    
    private init() {}
    
    @objc func handleStatusItemPressed(_ sender: Any?) {
        if userDefaultsManager.windowPopOut {
            togglePopOutWindow(sender)
        }
        else {
           showWindow()
        }
    }
    
    @objc func handleToggleWindow() {
        if userDefaultsManager.windowPopOut {
            if self.window != nil {
                window?.orderOut(nil)
            }
            self.window = nil
            self.togglePopOutWindow(nil)
        }
        else {
            if self.window == nil {
                self.setupWindow()
            }
            else {
                self.toggleWindow()
            }
        }
    }
    
    func handleResetWindow() {
        if userDefaultsManager.windowPopOut {
            if self.window != nil {
                window?.orderOut(nil)
            }
            self.window = nil
            resetPopOutWindow()
        }
        else {
            if window == nil {
                setupWindow()
            }
            else {
                resetWindow()
            }
        }
    }
    
    func setupApp() {
        self.menuManager?.setupStatusBar()
                    
        self.contentView = AnyView(
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(clipboardManager)
                .environmentObject(self)
                .environmentObject(menuManager!)
        )
                                
        NSApplication.shared.mainMenu = nil
//        self.menuManager.setupMainMenu(isCopyingPaused: nil)
        self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
        
        if UserDefaultsManager.shared.windowPopOut {
            self.setupPopOutWindow()
        }
        else {
            self.setupWindow()
        }
    }
    
    func setupWindow() {
        NSApp.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: userDefaultsManager.windowWidth, height: userDefaultsManager.windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        
        window.title = userDefaultsManager.appName
        
        let hostingController = NSHostingController(rootView: self.contentView)
        
        let windowWidth: CGFloat = userDefaultsManager.windowWidth
        let windowHeight: CGFloat = userDefaultsManager.windowHeight
        
        hostingController.view.frame.size = CGSize(width: windowWidth, height: windowHeight)
        window.contentViewController = hostingController
        
        let screen = window.screen ?? NSScreen.main!
        
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
        
        window.collectionBehavior = [] // No special behavior
        
        if UserDefaultsManager.shared.canWindowFloat {
            window.level = .floating
        }
        if UserDefaultsManager.shared.windowOnAllDesktops {
            window.collectionBehavior = .canJoinAllSpaces
        }
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        
        //                    window.standardWindowButton(.closeButton)?.isHidden = true
        //                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        //                    window.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.window = window
        
    }
        
    func resetWindow() {
//        if let window = NSApplication.shared.windows.first {
        if let window = self.window {
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
            
            self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
        }
    }
    
    @objc func toggleWindow() {
        //                print("Cmd-Shift-C pressed: Toggling window visibility")
        
        DispatchQueue.main.async {
//            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = self.window {
                if !window.isKeyWindow {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
//                    if self.userDefaultsManager.windowOnAllDesktops {
                    if UserDefaultsManager.shared.windowOnAllDesktops {
                        window.collectionBehavior = .canJoinAllSpaces
                    }
//                    if self.userDefaultsManager.canWindowFloat {
                    if UserDefaultsManager.shared.canWindowFloat {
                        window.level = .floating
                    }
                    self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
                }
                else {
                    print("hiding")
                    self.hideWindow()
                }
            }
        }
    }
    
    @objc func showWindow() {
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
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
            else {
                self.setupWindow()
            }
        }
    }
    
    @objc func hideWindow() {
        DispatchQueue.main.async {
            NSApp.hide(nil)
            print("hid")
        }
    }
    
    
    //POPOVER STARTS HERE
    
    func setupPopOutWindow() {
//        print("setup Pop Out window")
        
        if self.popover == nil {
            self.popover = NSPopover()
        }
                
        let hostingController = NSHostingController(rootView: self.contentView.focusable(true))
        let windowWidth: CGFloat = userDefaultsManager.windowWidth
        let windowHeight: CGFloat = userDefaultsManager.windowHeight
        hostingController.view.frame.size = CGSize(width: windowWidth, height: windowHeight)
        popover?.contentViewController = hostingController
        
        popover?.behavior = .transient // makes window close when you click outside of it
        
        //testing
        if let popoverWindow = popover?.contentViewController?.view.window {
            popoverWindow.makeKeyAndOrderFront(nil)
            popoverWindow.makeFirstResponder(popoverWindow.contentView)
        }
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        NSApp.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
        popover?.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
            
        self.popover?.backgroundColor = UserDefaultsManager.shared.darkMode ? darkModeBackground : lightModeBackground

        self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
            if let button = self.menuManager?.statusBarItem?.button {
                self.popover?.show(relativeTo: button.frame, of: button, preferredEdge: .minY)
                self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
            }
        }
    }
    
    func togglePopOutWindow(_ sender: Any?) {
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
        
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
                else {
                    print("toggle popover hit ELSE for some reason")
                }
            }
        }
    }
    
    func hidePopOutWindow() {
        self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
        
        popover?.close()
    }
    
    func showPopOutWindow() {
        if let button = menuManager?.statusBarItem?.button {
            
            self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
            
            NSApplication.shared.activate(ignoringOtherApps: true)
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func resetPopOutWindow() {
        if self.popover == nil {
            setupPopOutWindow()
            return
        }
        
        let windowWidth: CGFloat = CGFloat(UserDefaults.standard.float(forKey: "windowWidth"))
        let windowHeight: CGFloat = CGFloat(UserDefaults.standard.float(forKey: "windowHeight"))
                
        popover?.contentSize = NSSize(width: windowWidth, height: windowHeight)
                
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        NSApp.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
        popover?.appearance = NSAppearance(named: UserDefaultsManager.shared.darkMode ? .darkAqua : .vibrantLight)
        
        self.popover?.backgroundColor = UserDefaultsManager.shared.darkMode ? darkModeBackground : lightModeBackground
        
        self.menuManager?.updateMainMenu(isCopyingPaused: nil, shouldDelay: true)
        
        showPopOutWindow()
    }
}

// this is how I can get the popover to have a custom background color
extension NSPopover {
    
    private struct Keys {
        static var backgroundViewKey = "backgroundKey"
    }
    
    private var backgroundView: NSView {
//        let bgView = objc_getAssociatedObject(self, &Keys.backgroundViewKey) as? NSView
        let bgView = withUnsafePointer(to: &Keys.backgroundViewKey) { keyPointer in
            return objc_getAssociatedObject(self, keyPointer) as? NSView
        }
        if let view = bgView {
            return view
        }
        
        let view = NSView()
//        objc_setAssociatedObject(self, &Keys.backgroundViewKey, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        withUnsafePointer(to: &Keys.backgroundViewKey) { keyPointer in
            objc_setAssociatedObject(self, keyPointer, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(popoverWillOpen(_:)), name: NSPopover.willShowNotification, object: nil)
        return view
    }
    
    @objc private func popoverWillOpen(_ notification: Notification) {
        if backgroundView.superview == nil {
            if let contentView = contentViewController?.view, let frameView = contentView.superview {
                frameView.wantsLayer = true
                backgroundView.frame = NSInsetRect(frameView.frame, 1, 1)
                backgroundView.autoresizingMask = [.width, .height]
                frameView.addSubview(backgroundView, positioned: .below, relativeTo: contentView)
            }
        }
    }
    
    var backgroundColor: NSColor? {
        get {
            if let bgColor = backgroundView.layer?.backgroundColor {
                return NSColor(cgColor: bgColor)
            }
            return nil
        }
        set {
            backgroundView.wantsLayer = true
            backgroundView.layer?.backgroundColor = newValue?.cgColor
        }
    }
}
