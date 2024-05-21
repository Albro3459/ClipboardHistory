//
//  ClipboardMonitor.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/17/24.
//

import QuickLookThumbnailing
import SwiftUI
import Combine
import Cocoa
import CoreData

class ClipboardMonitor: ObservableObject {
    private var checkTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
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
            //            let context = PersistenceController.shared.container.viewContext
            
//            print("Copied: ")
            
            let imageExtensions = ["tiff", "jpeg", "jpg", "png", "svg", "gif"]
            
            // Check for file URLs first
            if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let fileUrl = fileUrls.first {
//                print(fileUrl)
                let fileExtension = fileUrl.pathExtension.lowercased()
                
                if imageExtensions.contains(fileExtension) {
                    if let image = NSImage(contentsOf: fileUrl) {
//                        print("Image")
                        self.saveClipboard(content: fileUrl.lastPathComponent, type: "image", imageData: image.tiffRepresentation, fileName: fileUrl.path)
                    }
                } else {
                    do {
                        let resourceValues = try fileUrl.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isAliasFileKey, .isUbiquitousItemKey, .volumeIsRemovableKey])
                        
                        if let isDirectory = resourceValues.isDirectory, isDirectory {
//                            print("Folder")
                            self.saveClipboard(content: fileUrl.lastPathComponent, type: "folder", imageData: nil, fileName: fileUrl.path)
                        } else if let isSymbolicLink = resourceValues.isSymbolicLink, isSymbolicLink {
//                            print("Symbolic Link")
                            self.saveClipboard(content: fileUrl.lastPathComponent, type: "symlink", imageData: nil, fileName: fileUrl.path)
                        } else if let isAliasFile = resourceValues.isAliasFile, isAliasFile {
//                            print("Alias File")
                            self.saveClipboard(content: fileUrl.lastPathComponent, type: "alias", imageData: nil, fileName: fileUrl.path)
//                        } else if let isUbiquitousItem = resourceValues.isUbiquitousItem, isUbiquitousItem {
//                            print("Ubiquitous Item (iCloud)")
//                            self.saveClipboard(content: fileUrl.lastPathComponent, type: "icloud", imageData: nil, fileName: fileUrl.path)
                        } else if let volumeIsRemovable = resourceValues.volumeIsRemovable, volumeIsRemovable {
//                            print("Removable Drive")
                            self.saveClipboard(content: fileUrl.lastPathComponent, type: "removable", imageData: nil, fileName: fileUrl.path)
                        } else {
//                            print("File")
//                            print(fileUrl.path + " | " + fileUrl.lastPathComponent)
                            self.generateThumbnail(for: fileUrl.path) { thumbnail in
                                self.saveClipboard(content: fileUrl.lastPathComponent, type: "file", imageData: thumbnail?.tiffRepresentation, fileName: fileUrl.path)
                            }
                        }
                    } catch {
                        print("Error checking file type: \(error)")
                    }
                }
            }
            // Working
            else if let imageData = pasteboard.data(forType: .tiff), let image = NSImage(data: imageData) {
//                                print("Image DATA")
                self.saveClipboard(content: "Screenshot", type: "imageData", imageData: image.tiffRepresentation, fileName: nil)
            }
            // Working
            else if let content = pasteboard.string(forType: .string) {
                                print("String")
                
                self.saveClipboard(content: content, type: "text", imageData: nil, fileName: nil)
            }
            
//            print("\n")
        }
    }
    
    private func saveClipboard(content: String?, type: String, imageData: Data?, fileName: String?) {
        if !checkLast(content: content, type: type, imageData: imageData, fileName: fileName) {
            return
        }
        
        DispatchQueue.main.async {
            
            let context = PersistenceController.shared.container.viewContext
            
            // Wrap database operations within a perform block for atomic execution
            context.perform {
                let newClipboardItem = ClipboardItem(context: context)
                newClipboardItem.content = content
                newClipboardItem.timestamp = Date()
                newClipboardItem.type = type
                newClipboardItem.imageData = imageData
                newClipboardItem.fileName = fileName
                
                // Manage clipboard item limit
                let fetchRequest: NSFetchRequest<ClipboardItem> = ClipboardItem.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
                
                //                    let items = try? context.fetch(fetchRequest)
                //                    print("item count: \(String(describing: items?.count))\n")
                
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
    
    private func checkLast(content: String?, type: String, imageData: Data?, fileName: String?) -> Bool {
        var shouldSave = false
        
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ClipboardItem.fetchRequest()
        fetchRequest.fetchLimit = 30
        fetchRequest.propertiesToFetch = ["content"]
        fetchRequest.resultType = .dictionaryResultType
        
        do {
            let results = try context.fetch(fetchRequest) as? [[String: Any]] // Cast directly to an array of dictionaries
            
            if results?.last == nil {
                shouldSave = true
            } else if let firstResult = results?.last, let lastContent = firstResult["content"] as? String {
                if lastContent != content {
                    shouldSave = true
                }
            }
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
        }
        return shouldSave
    }
    
    private func generateThumbnail(for filePath: String?, completion: @escaping (NSImage?) -> Void) {
        guard let filePath = filePath else {
            completion(nil)
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let size = CGSize(width: 100, height: 100)
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: size, scale: scale, representationTypes: .thumbnail)
        
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { (thumbnail, _, error) in
            if let error = error {
                print("Thumbnail generation failed: \(error)")
                completion(nil)
            } else if let thumbnail = thumbnail {
                let nsImage = NSImage(cgImage: thumbnail.cgImage, size: size)
                completion(nsImage)
            } else {
                completion(nil)
            }
        }
    }
    
    deinit {
        checkTimer?.invalidate()
    }
}

