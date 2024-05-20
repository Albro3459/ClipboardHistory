//
//  ClipboardMonitor.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/17/24.
//

import Combine
import Cocoa
import CoreData

class ClipboardMonitor: ObservableObject {
    private var checkTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
//    @Published var lastChangeCount: Int = NSPasteboard.general.changeCount

    
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
                let context = PersistenceController.shared.container.viewContext

                // Wrap database operations within a perform block for atomic execution
                context.perform {
                    let newClipboardItem = ClipboardItem(context: context)
                    newClipboardItem.content = content
                    newClipboardItem.timestamp = Date()
                    newClipboardItem.type = "text"

                    // Manage clipboard item limit
                    let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

//                    let items = try? context.fetch(fetchRequest)
//                    print("item count: \(String(describing: items?.count))")
                    
                    if let items = try? context.fetch(fetchRequest), items.count > 30 {
                        context.delete(items.first!) // Delete the oldest item
                    }

                    // Attempt to save the context with changes
                    do {
                        try context.save()
                    } catch {
                        print("Failed to save context after updating clipboard items: \(error)")
                    }
                }
            }
        }
    }
    
    deinit {
        checkTimer?.invalidate()
    }
}

