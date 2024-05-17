//
//  ContentView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: ClipboardItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default)
    private var clipboardItems: FetchedResults<ClipboardItem>

    var body: some View {
        List {
            ForEach(clipboardItems, id: \.self) { item in
                VStack(alignment: .leading) {
                    Text(item.content ?? "Unknown content")
                        .font(.headline)
                    Text("Type: \(item.type ?? "Unknown")")
                        .font(.subheadline)
                    Text("Saved at \(item.timestamp!, formatter: itemFormatter)")
                        .font(.footnote)
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()


#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
