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
    }
    
    public func pasteNoFormatting() {
        let pasteboard = NSPasteboard.general
        
        // Check for file URLs first
        if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let _ = fileUrls.first {
            // Handle file URLs if necessary
        } else if let imageData = pasteboard.data(forType: .tiff), let _ = NSImage(data: imageData) {
            // Handle images if necessary
        } else if let rtfData = pasteboard.data(forType: .rtf) {
            // Handle RTF data and convert it to plain text
            if let attributedString = try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                let plainText = attributedString.string
                updatePasteboard(with: plainText)
//                print("RTF data found and converted to plain text")
            }
        } else if let htmlData = pasteboard.data(forType: .html) {
            // Handle HTML data and convert it to plain text
            if let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                let plainText = attributedString.string
                updatePasteboard(with: plainText)
//                print("HTML data found and converted to plain text")
            }
        } else if let content = pasteboard.string(forType: .string) {
            // Handle plain string data
            updatePasteboard(with: content)
//            print("Plain string data found")
        } else {
//            print("No suitable data found on the pasteboard")
//            print("No suitable data found on the pasteboard")
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
//        Accessibility.check()
        
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
    
}

extension KeyboardShortcuts.Name {
    static var toggleVisibility = Self("toggleVisibility", default: .init(.c, modifiers: [.command, .shift]))
    static var pasteNoFormatting = Self("pasteNoFormatting", default: .init(.v, modifiers: [.command, .shift]))
}


//struct Accessibility {
//    private static var alert: NSAlert {
//        let alert = NSAlert()
//        alert.alertStyle = .warning
//        alert.messageText = NSLocalizedString("accessibility_alert_message", comment: "")
//        alert.addButton(withTitle: NSLocalizedString("accessibility_alert_deny", comment: ""))
//        alert.addButton(withTitle: NSLocalizedString("accessibility_alert_open", comment: ""))
//        alert.icon = NSImage(named: "NSSecurity")
//
//        var locationName = NSLocalizedString("system_settings_name", comment: "")
//        var paneName = NSLocalizedString("system_settings_pane", comment: "")
//        if #unavailable(macOS 13) {
//            locationName = NSLocalizedString("system_preferences_name", comment: "")
//            paneName = NSLocalizedString("system_preferences_pane", comment: "")
//        }
//
//        alert.informativeText = NSLocalizedString("accessibility_alert_comment", comment: "")
//            .replacingOccurrences(of: "{settings}", with: locationName)
//            .replacingOccurrences(of: "{pane}", with: paneName)
//
//        return alert
//    }
//    private static var allowed: Bool { AXIsProcessTrustedWithOptions(nil) }
//    private static let url = URL(
//        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
//    )
//
//    static func check() {
//        guard !allowed else { return }
//
//        // Show accessibility window async to allow menu to close.
//        DispatchQueue.main.async {
//            if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn,
//               let url = url {
//                NSWorkspace.shared.open(url)
//            }
//        }
//    }
//}
