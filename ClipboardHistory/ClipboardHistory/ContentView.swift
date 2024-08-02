//
//  ContentView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import SwiftUI
import CoreData
import KeyboardShortcuts

enum ActiveAlert {
    case clear, delete
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ClipboardItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
        animation: nil)
    private var fetchedClipboardItems: FetchedResults<ClipboardItem>
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @State private var showingAlert = false
    @State private var activeAlert: ActiveAlert = .clear

    @State private var atTopOfList = true
        
//    @State private var selectedItem: ClipboardItem?
    
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    @State private var multiSelection = Set<UUID>()
    @State private var isSelectingCategory: Bool = false
    
    private var clipboardItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(fetchedClipboardItems)
        }
        else {
            return fetchedClipboardItems.filter {
                ($0.content?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.type?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = false
                }
            VStack {
                HStack {
                    SearchBarView(searchText: $searchText)
//                        .padding(.trailing, 4)
                        .focused($isFocused)
                    
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .foregroundColor(.gray)
                        .padding(.trailing, 6)
                        .onTapGesture {
                            isSelectingCategory.toggle()
//                            isTextFieldFocused = false
                        }
                    
                }
                .padding(.top, 2)
                .padding(.bottom, -8)
                
//                .overlay( // Adds a thin line at the bottom
//                    Rectangle().frame(height: 0.5).foregroundColor(.black.opacity(0.5)), alignment: .bottom
//                )
//                .padding(0)

                
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.onChange(of: geometry.frame(in: .named("ScrollViewArea")).minY) { oldValue, newValue in
                            atTopOfList = newValue >= 0
                            // print(atTopOfList)
                        }
                    }
                    .frame(height: 0)
                    .padding(0)
                    
//                    if isSelectingCategory {
//                        TypeDropDownMenu(multiSelection: $multiSelection)
//                            .frame(width: 200, height: 150) // Adjust size as necessary
////                            .popover(isPresented: $isSelectingCategory, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
////                                TypeDropDownMenu(multiSelection: $multiSelection)
////                                    .frame(width: 200, height: 150) // Adjust size as necessary
////                            }
//                    }
                    
                    ScrollViewReader { scrollView in
                        LazyVStack(spacing: 0) {
                            ForEach(clipboardItems, id: \.self) { item in
                                ClipboardItemView(item: item, isSelected: Binding(
                                    get: { self.clipboardManager.selectedItem == item },
                                    set: { newItem in
                                        self.clipboardManager.selectedItem = newItem ? item : nil
                                        isFocused = false
                                    }))
                                .id(item.objectID)
                                .animation(atTopOfList ? .default : nil, value: clipboardItems.first?.objectID)
                                
                            }
                            .padding(.top, 5)
                            .padding(.bottom, -5)
                        }
                        .padding(.top, -10)
                        .onChange(of: clipboardManager.selectedItem, initial: false) {
                            if let selectedItem = clipboardManager.selectedItem, let index = clipboardItems.firstIndex(of: selectedItem) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollView.scrollTo(clipboardItems[index].objectID)
                                }
                                //                                isFocused = false
                            }
                            //                            else {
                            //                                isFocused = true
                            //                            }
                        }
                    }
                }
                .coordinateSpace(name: "ScrollViewArea")
                .overlay( // Adds a thin line at the bottom
                    Rectangle().frame(height: 0.5).foregroundColor(.black.opacity(0.5)), alignment: .top
                )
                .overlay(
                    Rectangle().frame(height: 0.5).foregroundColor(.black.opacity(0.5)), alignment: .bottom
                )
                Spacer()
                Button {
                    showingAlert = true
                    activeAlert = .clear
                } label: {
                    Text("Clear All")
                        .frame(maxWidth: 90)
                }
                .buttonStyle(.bordered)
                .tint(Color(.darkGray))
                .padding(.bottom, 8)
                .alert(isPresented: $showingAlert) {
                    if activeAlert == .clear {
                        Alert(
                            title: Text("Confirm Clear"),
                            message: Text("Are you sure you want to clear all clipboard items?"),
                            primaryButton: .destructive(Text("Clear")) {
                                clearClipboardItems()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    else {
                        Alert(
                            title: Text("Confirm Delete"),
                            message: Text("Are you sure you want to delete this clipboard item?"),
                            primaryButton: .destructive(Text("Delete")) {
                                self.deleteItem(item: clipboardManager.selectedItem!)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .onAppear {
                    clipboardManager.selectedItem = clipboardItems.first
                }
                
            }
            .onAppear {
//                clipboardManager.selectedItem = clipboardItems.first
                setUpKeyboardHandling()
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
    
    private func deleteItem(item: ClipboardItem) {
        viewContext.delete(item)
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
    
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            var currentIndex: Int?
            if clipboardManager.selectedItem != nil {
                currentIndex = clipboardItems.firstIndex(of: clipboardManager.selectedItem!)
            }
            if currentIndex == nil {
                if !clipboardItems.isEmpty {
                    clipboardManager.selectedItem = clipboardItems[0]
                    currentIndex = 0
                }
                else {
                    return event
                }
            }
            
            if event.type == .keyDown {
                switch event.keyCode {
                case 8:
                    if event.modifierFlags.contains(.command) {
                        // Handle Command + C
                        clipboardManager.copySelectedItem()
                        return nil // no more beeps
                    }
                case 51:
                    if event.modifierFlags.contains(.command) {
                        DispatchQueue.main.async {
                            self.showingAlert = true // Trigger the alert
                            activeAlert = .delete
                        }
                        return nil
                    }
                case 126:
                    // Handle up arrow
                    if currentIndex != nil && currentIndex! > 0 {
                        clipboardManager.selectedItem = clipboardItems[currentIndex!-1]
                    }
                    return nil //no more beeps
                case 125:
                    // Handle down arrow
                    if currentIndex != nil && currentIndex! < clipboardItems.count - 1 {
                        clipboardManager.selectedItem = clipboardItems[currentIndex!+1]
                    }
                    return nil // no more beeps
//                case 53:
//                    DispatchQueue.main.async {
//                        self.isSearchBarFocused = false
//                    }
//                    print("here")
//                    return nil
                default:
                    break
                }
            }
            return event
        }
    }
    
}


struct ClipboardItemView: View {
    var item: ClipboardItem
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @State private var showingDeleteAlert = false
    
    @Binding var isSelected: Bool
    @State private var selectedContent:  String?
            
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if item.type == "text", let content = item.content {
                    if item.type == "text" {
                        Text(content)
                            .font(.headline)
                            .frame(minHeight: 33)
                            .lineLimit(3)
                    }
                }
                else if item.type == "imageData" || item.type == "image" || item.type == "file", 
                                let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70)
                    
                    if item.type != "imageData", let content = item.content {
                        Text(content)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                }
                else if item.type == "folder" || item.type == "alias", let content = item.content {
                    Image("FolderThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                    Text(content)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                }
            }
            .padding(.all, 10)
           
            Spacer()
            Button(action: {
                self.copyToClipboard(item: item)
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.white)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Button(action: {
                isSelected = true
                clipboardManager.selectedItem = item
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.leading, 5)
            .padding(.trailing, 10)
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this clipboard item?"),
                    primaryButton: .destructive(Text("Delete")) {
                        self.deleteItem(item: clipboardManager.selectedItem!)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .padding(.top, 4)
        .padding(.leading, 15)
        .padding(.trailing, 15)
        .padding(.bottom, 2)
//        .overlay( // Adds a thin line at the bottom
//            Rectangle().frame(height: 1).foregroundColor(.gray), alignment: .bottom
//        )
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(!isSelected ? Color(.darkGray).opacity(0.5) : Color(.darkGray))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        )
        .contentShape(Rectangle()) // Makes the entire area tappable
        .onTapGesture {
            isSelected = true
        }
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
