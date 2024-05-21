//
//  Persistence.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        // Create a few sample items for the Preview
        for _ in 0..<10 {
            let newItem = ClipboardItem(context: viewContext)
            newItem.content = "Sample content"
            newItem.type = "text"
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            fatalError("Unresolved error \(error), \((error as NSError).userInfo)")
        }
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ClipboardHistory")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true

    }
}
