//
//  ClipboardMonitor.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/17/24.
//

import Combine
import Cocoa

class ClipboardMonitor: ObservableObject {
    private var checkTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    @Published var clipboardItems: [String] = [] // Example property
    
    func startMonitoring() {
        checkTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkClipboard), userInfo: nil, repeats: true)
    }
    
    @objc private func checkClipboard() {
        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            if pasteboard.changeCount != self.lastChangeCount {
                self.lastChangeCount = pasteboard.changeCount
                self.processDataFromClipboard()
            }
        }
    }
    
    private func processDataFromClipboard() {
            DispatchQueue.main.async {
                let pasteboard = NSPasteboard.general
                if let content = pasteboard.string(forType: .string) {
                    let newClipboardItem = ClipboardItem(context: PersistenceController.shared.container.viewContext)
                    newClipboardItem.content = content
                    newClipboardItem.timestamp = Date()
                    newClipboardItem.type = "text"
                    
                    do {
                        try PersistenceController.shared.container.viewContext.save()
                    } catch {
                        print("Failed to save clipboard item: \(error)")
                    }
                }
            }
        }
    
    deinit {
        checkTimer?.invalidate()
    }
}
