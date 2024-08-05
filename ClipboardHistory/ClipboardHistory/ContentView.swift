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
    
//    @State private var isCopied = false
    
    @State private var showingAlert = false
    @State private var activeAlert: ActiveAlert = .clear

    @State private var atTopOfList = true
            
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    @State private var isSelectingCategory: Bool = false
    @State private var selectedTypes: Set<UUID> = []
        
    private var clipboardItems: [ClipboardItem] {
        
        let selectedTypeNames: [String] = selectedTypes.map { id in
            ClipboardType.getTypeName(by: id)
        }
        
        return fetchedClipboardItems.filter { item in
            let typeMatch: Bool
            if selectedTypes.isEmpty || selectedTypes.count == 3 {
                typeMatch = true // No filtering by type when none or all are selected.
            } else {
                typeMatch = selectedTypeNames.contains { typeName in
                    if typeName == "fileFolder" {
                        item.type?.localizedCaseInsensitiveContains("file") ?? false ||
                        item.type?.localizedCaseInsensitiveContains("folder") ?? false ||
                        item.type?.localizedCaseInsensitiveContains("image") ?? false
                    }
                    else {
                        item.type?.localizedCaseInsensitiveContains(typeName) ?? false
                    }
                }
            }

            if searchText.isEmpty {
                return typeMatch
            } else {
                // Further filter by searchText if it is not empty.
                var searchTextMatch = false
                if searchText.contains("file".lowercased()) {
                    searchTextMatch = item.content?.localizedCaseInsensitiveContains(searchText) ?? false ||
                    item.type?.localizedCaseInsensitiveContains(searchText) ?? false || item.type?.localizedCaseInsensitiveContains("image") ?? false
                }
                else {
                    searchTextMatch = item.content?.localizedCaseInsensitiveContains(searchText) ?? false ||
                    item.type?.localizedCaseInsensitiveContains(searchText) ?? false
                }
                return searchTextMatch && typeMatch
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
            
            if clipboardManager.isCopied {
                ZStack(alignment: .center) {
                    
                    ZStack(alignment: .top) {
                        Rectangle()
                            .foregroundColor(Color(.darkGray))
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(Color(.darkGray))
                            .frame(height: 10)
                            .zIndex(1)
                    }
                    Text("Copied!")
                        .font(.subheadline)
                        .bold()
                        
                        .cornerRadius(8)
                        .frame(alignment: .center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: clipboardManager.isCopied)
                .position(x: 50, y: -211)
                .frame(width: 90, height: 24)
                .zIndex(5)
            
                
                Color.white.opacity(0.3).blink(duration: 0.3)
            }
            
            VStack {
                
                HStack {
                    SearchBarView(searchText: $searchText)
                        .focused($isFocused)
                    
                    Button(action: {
                        isSelectingCategory.toggle()
                        isFocused = false
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(.white)
                            .padding(.trailing, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $isSelectingCategory) {
                           TypeDropDownMenu(multiSelection: $selectedTypes)
                               .frame(width: 140, height: 99) 
                       }
                       .zIndex(1)
                    
                }
                .padding(.top, 2)
                .padding(.bottom, -8)
                    
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.onChange(of: geometry.frame(in: .named("ScrollViewArea")).minY) { oldValue, newValue in
                            atTopOfList = newValue >= 0
//                             print(atTopOfList)
                        }
                    }
                    .frame(height: 0)
                    .padding(0)
                    
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
//                            .padding(.top, 5)
//                            .padding(.bottom, -5)
                        }
                        .onChange(of: clipboardManager.selectedItem, initial: false) {
                            if let selectedItem = clipboardManager.selectedItem, let index = clipboardItems.firstIndex(of: selectedItem) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollView.scrollTo(clipboardItems[index].objectID)
                                }
                            }
                        }
                    }
                    .padding(.top, -4)
                }
                .coordinateSpace(name: "ScrollViewArea")
                .overlay( // Adds a thin line at the top and bottom
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
            
            if event.type == .keyDown && !self.showingAlert {
                switch event.keyCode {
                case 8:
                    if event.modifierFlags.contains(.command) {
                        // Handle Command + C
                        clipboardManager.copySelectedItem()
                        return nil // no more beeps
                    }
                case 36, 76:
                    // Handle Enter or Return
                    if !isFocused {
                        clipboardManager.copySelectedItem()
                        return nil // no more beeps
                    }
                case 51:
                    // Handle Command + Del
                    if event.modifierFlags.contains(.command) {
                        DispatchQueue.main.async {
                            self.showingAlert = true
                            activeAlert = .delete
                        }
                        return nil
                    }
                case 3:
                    if event.modifierFlags.contains(.command) {
                        // Handle Command + F
                        DispatchQueue.main.async {
                            isFocused = true
                        }
                        return nil // no more beeps
                    }
                case 53:
                    // Escape key
                    DispatchQueue.main.async {
                        isSelectingCategory = false
                        isFocused = false
                    }
                    return nil
                case 126:
                    // Handle up arrow
                    isFocused = false
                    if currentIndex != nil && currentIndex! > 0 {
                        clipboardManager.selectedItem = clipboardItems[currentIndex!-1]
                    }
                    return nil //no more beeps
                case 125:
                    // Handle down arrow
                    isFocused = false
                    if currentIndex != nil && currentIndex! < clipboardItems.count - 1 {
                        clipboardManager.selectedItem = clipboardItems[currentIndex!+1]
                    }
                    return nil // no more beeps
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
                            .frame(minHeight: 31)
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
                clipboardManager.selectedItem = item
//                self.copyToClipboard(item: item)
                clipboardManager.copySelectedItem()
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
        .padding(.bottom, 3)
        
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
    
//    private func copyToClipboard(item: ClipboardItem) {
//        let pasteboard = NSPasteboard.general
//        pasteboard.clearContents()
//        
//        switch item.type {
//        case "text":
//            if let content = item.content {
//                pasteboard.setString(content, forType: .string)
//            }
//        case "imageData":
//            if let imageData = item.imageData {
//                pasteboard.setData(imageData, forType: .tiff)
//            }
//        case "image", "file", "folder", "alias":
//            if let fileName = item.fileName {
//                let url = URL(fileURLWithPath: fileName)
//                pasteboard.writeObjects([url as NSURL])
//            }
//        default:
//            break
//        }
//    }
    
    private func deleteItem(item: ClipboardItem) {
        viewContext.delete(item)
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
    
}

struct BlinkViewModifier: ViewModifier {
    
    let duration: Double
    @State private var blink: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(blink ? 0 : 1)
            .animation(.easeOut(duration: duration)/*.repeatForever()*/, value: blink)
            .onAppear {
                withAnimation {
                    blink = true
                }
            }
    }
}

extension View {
    func blink(duration: Double = 0.75) -> some View {
        modifier(BlinkViewModifier(duration: duration))
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
