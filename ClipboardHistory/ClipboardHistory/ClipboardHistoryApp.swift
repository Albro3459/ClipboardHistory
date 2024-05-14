//
//  ClipboardHistoryApp.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import SwiftUI

@main
struct ClipboardHistoryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
