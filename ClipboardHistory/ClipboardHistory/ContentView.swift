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
        animation: nil)
    private var clipboardItems: FetchedResults<ClipboardItem>
    
    @State private var showingClearAlert = false
    @State private var atTopOfList = true
    
    var body: some View {
        VStack {
//            HStack {
//                Spacer()
//                SearchBarView()
//                    .padding(.trailing, 10)
//            } 
//            .padding(.top, 10)
//            .padding(.bottom, 5)
//            
            ScrollView {
                GeometryReader { geometry in
                    Color.clear.onChange(of: geometry.frame(in: .named("ScrollViewArea")).minY) { oldValue, newValue in
                        atTopOfList = newValue >= 0
                        // print(atTopOfList)
                    }
                }
                .frame(height: 0)
                
                LazyVStack {
                    ForEach(clipboardItems, id: \.self) { item in
                        ClipboardItemView(item: item)
                            .id(item.objectID)
                            .padding(.leading, 10)
                            .animation(atTopOfList ? .default : nil, value: clipboardItems.first?.objectID)
                        
                    }
                }
            }
            .coordinateSpace(name: "ScrollViewArea")
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
        } catch let error {
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
                if item.type == "text" {
                    Text(item.content ?? "Unknown content")
                        .font(.headline)
                        .lineLimit(3)
                }
                else if item.type == "imageData" || item.type == "image" || item.type == "file", let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                    if item.type != "imageData" {
                        Text(item.content ?? "Unknown content")
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                }
                else if item.type == "folder" || item.type == "alias"{
                    Image("FolderThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                    Text(item.content ?? "Unknown content")
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(action: {
                self.copyToClipboard(item: item)
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
    
    private func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case "text":
            if let content = item.content {
                pasteboard.setString(content, forType: .string)
            }
        case "imageData":
            if let imageData = item.imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
        case "image", "file", "folder", "alias":
            if let fileName = item.fileName {
                let url = URL(fileURLWithPath: fileName)
                pasteboard.writeObjects([url as NSURL])
            }
        default:
            break
        }
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


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()



#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
