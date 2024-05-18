//
//  ContentView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import SwiftUI
import CoreData

//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        entity: ClipboardItem.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
//        animation: .default)
//    private var clipboardItems: FetchedResults<ClipboardItem>
//
//    @State private var showingClearAlert = false
//
//    var body: some View {
//        VStack {
//            VStack {
//                ScrollViewReader { scrollProxy in
//                    List {
//                        ForEach(clipboardItems, id: \.self) { item in
//                            ClipboardItemView(item: item)
//                                .id(item.objectID)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            Button("Clear All") {
//                showingClearAlert = true
//            }
//            .buttonStyle(BorderlessButtonStyle())
//            .padding()
//            .alert(isPresented: $showingClearAlert) {
//                Alert(
//                    title: Text("Confirm Clear"),
//                    message: Text("Are you sure you want to clear all clipboard items?"),
//                    primaryButton: .destructive(Text("Clear")) {
//                        clearClipboardItems()
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//        }
//    }
//
//    private func clearClipboardItems() {
//        for item in clipboardItems {
//            viewContext.delete(item)
//        }
//        do {
//            try viewContext.save()
//        } catch {
//            print("Error saving managed object context: \(error)")
//        }
//    }
//}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: ClipboardItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: .default)
    private var clipboardItems: FetchedResults<ClipboardItem>

    @State private var lastItemID: NSManagedObjectID?
    @State private var showingClearAlert = false

    var body: some View {
        VStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack {
                        ForEach(clipboardItems, id: \.self) { item in
                            ClipboardItemView(item: item)
                                .id(item.objectID)
                                .padding(.leading, 10)
                        }
                    }
                    .onAppear {
                        lastItemID = clipboardItems.first?.objectID
                    }
                    .onChange(of: clipboardItems.count) { _, newCount in
                        if let newID = clipboardItems.first?.objectID, newID != lastItemID {
                            lastItemID = newID
                            withAnimation {
                                scrollProxy.scrollTo(newID, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            Spacer()
            Button("Clear All") {
                showingClearAlert = true
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding()
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text("Confirm Clear"),
                    message: Text("Are you sure you want to clear all clipboard items?"),
                    primaryButton: .destructive(Text("Clear")) {
                        clearClipboardItems()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func clearClipboardItems() {
        for item in clipboardItems {
            viewContext.delete(item)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
}


struct ClipboardItemView: View {
    var item: ClipboardItem
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingClearAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.content ?? "Unknown content")
                    .font(.headline)
                    .lineLimit(3)
                Text("Type: \(item.type ?? "Unknown")")
                    .font(.subheadline)
                Text("Saved at \(item.timestamp.map { itemFormatter.string(from: $0) } ?? "Unknown Date")")
                    .font(.footnote)
            }
            Spacer()
            Button(action: {
                self.copyToClipboard(content: item.content)
            }) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(BorderlessButtonStyle())
            Button(action: {
                showingClearAlert = true
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding()
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this clipboard item?"),
                    primaryButton: .destructive(Text("Delete")) {
                        self.deleteItem(item: self.item)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func copyToClipboard(content: String?) {
        guard let content = content else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
    
    private func deleteItem(item: ClipboardItem) {
        viewContext.delete(item)
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
}

//extension String {
//    func truncatedLines(to maxLines: Int = 3) -> String {
//        let lines = self.split(separator: "\n", maxSplits: maxLines, omittingEmptySubsequences: false)
//        if lines.count > maxLines {
//            return lines[0..<maxLines].joined(separator: "\n") + "..."
//        } else {
//            return self
//        }
//    }
//}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()


//#Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
