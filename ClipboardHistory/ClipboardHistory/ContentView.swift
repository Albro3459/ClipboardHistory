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

//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @FetchRequest(
//        entity: ClipboardGroup.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardGroup.timeStamp, ascending: false)],
//        animation: nil)
//    private var clipboardGroups: FetchedResults<ClipboardGroup>
//    
////    @EnvironmentObject var clipboardManager: ClipboardManager
//    
////    @State private var isCopied = false
//    
//
//    
//    var body: some View {
//        VStack {
//            ScrollView {
//                ForEach(clipboardGroups, id: \.self) { group in
//                    VStack(alignment: .leading) {
//                        ForEach(group.itemsArray, id: \.self) { item in
//                            Text(item.content ?? "No Content")
//                                .padding()
//                        }
//                    }
//                }
//            }
//        }
//    }
//}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ClipboardGroup.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardGroup.timeStamp, ascending: false)],
        animation: nil)
    private var clipboardGroups: FetchedResults<ClipboardGroup>
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
//    @State private var isCopied = false
    
    @State private var showingAlert = false
    @State private var activeAlert: ActiveAlert = .clear

    @State private var atTopOfList = true
            
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    @State private var isSelectingCategory: Bool = false
    @State private var selectedTypes: Set<UUID> = []
    
    @State private var scrollToTop: Bool = false
    @State private var scrollToBottom: Bool = false
    
    @State private var imageSizeMultiple: CGFloat = 1

        
//    private var clipboardItems: [ClipboardItem] {
//        
//        let selectedTypeNames: [String] = selectedTypes.map { id in
//            ClipboardType.getTypeName(by: id)
//        }
//        
//        return fetchedClipboardItems.filter { item in
//            let typeMatch: Bool
//            if selectedTypes.isEmpty || selectedTypes.count == 3 {
//                typeMatch = true // No filtering by type when none or all are selected.
//            } else {
//                typeMatch = selectedTypeNames.contains { typeName in
//                    if typeName == "fileFolder" {
//                        item.type?.localizedCaseInsensitiveContains("file") ?? false ||
//                        item.type?.localizedCaseInsensitiveContains("folder") ?? false ||
//                        item.type?.localizedCaseInsensitiveContains("image") ?? false
//                    }
//                    else {
//                        item.type?.localizedCaseInsensitiveContains(typeName) ?? false
//                    }
//                }
//            }
//
//            if searchText.isEmpty {
//                return typeMatch
//            } else {
//                // Further filter by searchText if it is not empty.
//                var searchTextMatch = false
//                if searchText.contains("file".lowercased()) {
//                    searchTextMatch = item.content?.localizedCaseInsensitiveContains(searchText) ?? false ||
//                    item.type?.localizedCaseInsensitiveContains(searchText) ?? false || item.type?.localizedCaseInsensitiveContains("image") ?? false
//                }
//                else {
//                    searchTextMatch = item.content?.localizedCaseInsensitiveContains(searchText) ?? false ||
//                    item.type?.localizedCaseInsensitiveContains(searchText) ?? false
//                }
//                return searchTextMatch && typeMatch
//            }
//        }
//    }
    
    var body: some View {
        ZStack {
            
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = false
                }
            
//            if clipboardManager.isCopied {
//                ZStack(alignment: .center) {
//                    
//                    ZStack(alignment: .top) {
//                        Rectangle()
//                            .foregroundColor(Color(.darkGray))
//                            .cornerRadius(8)
//                        Rectangle()
//                            .foregroundColor(Color(.darkGray))
//                            .frame(height: 10)
//                            .zIndex(1)
//                    }
//                    Text("Copied!")
//                        .font(.subheadline)
//                        .bold()
//                        
//                        .cornerRadius(8)
//                        .frame(alignment: .center)
//                }
//                .transition(.move(edge: .top).combined(with: .opacity))
//                .animation(.easeInOut, value: clipboardManager.isCopied)
//                .position(x: 50, y: -211)
//                .frame(width: 90, height: 24)
//                .zIndex(5)
//            
//                
//                Color.white.opacity(0.1).flash(duration: 0.3)
//            }
            
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
                            .padding(.trailing, -2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $isSelectingCategory) {
                           TypeDropDownMenu(multiSelection: $selectedTypes)
                               .frame(width: 140, height: 99) 
                       }
                       .zIndex(1)
                       .help("Filter Items by Type")
                    
                    Button(action: {
                        if !atTopOfList {
                            scrollToTop = true
                        }
                        else {
                            scrollToBottom = true
                        }
                    }) {
                        Image(systemName: !atTopOfList ? "arrow.up.circle" : "arrow.down.circle")
                            .foregroundColor(.white)
                            .padding(.trailing, 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(!atTopOfList ? "Scroll to Top" : "Scroll to Bottom")
                    
                }
                .padding(.top, 2)
                .padding(.bottom, -8)
                    
                ScrollView(showsIndicators: false) {
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
                            ForEach(clipboardGroups, id: \.self) { group in
                                if group.count == 1, let item = group.itemsArray.first {
                                    ClipboardItemView(item: item, imageSizeMultiple: $imageSizeMultiple, isSelected: Binding(
                                        get: { self.clipboardManager.selectedItem == item },
                                        set: { newItem in
                                            self.clipboardManager.selectedItem = newItem ? item : nil
                                            isFocused = false
                                        }))
                                    .id(item.objectID)
                                }
                                else if group.count > 1 {
                                    ClipboardGroupView(group: group, isGroupSelected: Binding(
                                        get: { self.clipboardManager.selectedGroup == group },
                                        set: { newGroup in
                                            self.clipboardManager.selectedGroup = newGroup ? group : nil
                                            isFocused = false
                                        }))
                                    .id(group.objectID)
                                }
//
                            }
                        } //scrolls when using the arrow keys
                        .onChange(of: clipboardManager.selectedGroup, initial: false) {
                            if let selectedGroup = clipboardManager.selectedGroup, let _ = clipboardGroups.firstIndex(of: selectedGroup) {
//                                withAnimation(.easeInOut(duration: 0.5)) {
//                                    scrollView.scrollTo(clipboardGroups[index].objectID)
//                                }
                                clipboardManager.selectedItem = nil
                            }
                        }
                        .onChange(of: clipboardManager.selectedItem, initial: false) {
                            if let _ = clipboardManager.selectedItem {
                                    clipboardManager.selectedGroup = nil
                            }
                         }
//                        .onChange(of: scrollToTop, initial: false) {
//                            withAnimation() {
//                                scrollView.scrollTo(clipboardItems.first?.objectID, anchor: .top)
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
////                                    scrollView.scrollTo(firstItem.objectID, anchor: .top)
//                                }
//                                scrollToTop = false
//                            }
//                        }
//                        .onChange(of: scrollToBottom, initial: false) {
//                            withAnimation() {
//                                scrollView.scrollTo(clipboardItems.last?.objectID)
//                                scrollToBottom = false
//                            }
//                        }
                    }
                    .padding(.top, -4)
                }
                .coordinateSpace(name: "ScrollViewArea")
                .overlay( // Adds a thin line at the top and bottom
                    Rectangle().frame(height: 0.5).foregroundColor(.black.opacity(0.5)), alignment: .top
                )
//                .overlay(
//                    Rectangle().frame(height: 0.5).foregroundColor(.black.opacity(0.5)), alignment: .bottom
//                )
                Spacer()
                Button {
                    showingAlert = true
                    activeAlert = .clear
                } label: {
                    Text("Clear All")
                        .frame(maxWidth: 90)
                }
                .help("Clear All Items")
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
//                .onAppear {
//                    clipboardManager.selectedItem = clipboardItems.first
//                }

            }
//            .onAppear {
////                clipboardManager.selectedItem = clipboardItems.first
//                setUpKeyboardHandling()
//            }
        }
    }
    
    private func clearClipboardItems() {
        
        clipboardManager.clipboardMonitor?.clearTmpImages()
        
        for item in clipboardGroups {
            viewContext.delete(item)
        }
        do {
            try viewContext.save()
        } catch let error {
            print("Error saving managed object context: \(error)")
        }
    }
    
    private func deleteItem(item: ClipboardItem) {

        if let imageHash = item.imageHash, let filePath = item.filePath, !filePath.isEmpty {
            
            let folderPath = clipboardManager.clipboardMonitor?.tmpFolderPath
            
            if filePath.contains(folderPath!.path()) {
                
                let items = clipboardManager.clipboardMonitor?.findItems(content: nil, type: nil, imageHash: imageHash, filePath: filePath, context: nil)
                
                // only want to delete file if its the only copy left
                if items!.count < 2 {
                    print(items!.count)
                    clipboardManager.clipboardMonitor?.deleteTmpImage(filePath: filePath)
                }
            }
        }
        
        viewContext.delete(item)
            
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
    
//    private func setUpKeyboardHandling() {
//        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
//            var currentIndex: Int?
//            if clipboardManager.selectedItem != nil {
//                currentIndex = clipboardItems.firstIndex(of: clipboardManager.selectedItem!)
//            }
//            if currentIndex == nil {
//                if !clipboardItems.isEmpty {
//                    clipboardManager.selectedItem = clipboardItems[0]
//                    currentIndex = 0
//                }
//                else {
//                    return event
//                }
//            }
//            
//            if event.type == .keyDown && !self.showingAlert {
//                switch event.keyCode {
//                case 8:
//                    if event.modifierFlags.contains(.command) {
//                        // Handle Command + C
//                        clipboardManager.copySelectedItem()
//                        return nil // no more beeps
//                    }
//                case 36, 76:
//                    // Handle Enter or Return
//                    if !isFocused {
//                        clipboardManager.copySelectedItem()
//                        return nil // no more beeps
//                    }
//                case 51:
//                    // Handle Command + Del
//                    if event.modifierFlags.contains(.command) {
//                        DispatchQueue.main.async {
//                            self.showingAlert = true
//                            activeAlert = .delete
//                        }
//                        return nil
//                    }
//                case 3:
//                    if event.modifierFlags.contains(.command) {
//                        // Handle Command + F
//                        DispatchQueue.main.async {
//                            isFocused = true
//                        }
//                        return nil // no more beeps
//                    }
//                case 53:
//                    // Escape key
//                    DispatchQueue.main.async {
//                        isSelectingCategory = false
//                        isFocused = false
//                    }
//                    return nil
//                case 126:
//                    // Handle up arrow
//                    isFocused = false
//                    if currentIndex != nil && currentIndex! > 0 {
//                        clipboardManager.selectedItem = clipboardItems[currentIndex!-1]
//                    }
//                    return nil //no more beeps
//                case 125:
//                    // Handle down arrow
//                    isFocused = false
//                    if currentIndex != nil && currentIndex! < clipboardItems.count - 1 {
//                        clipboardManager.selectedItem = clipboardItems[currentIndex!+1]
//                    }
//                    return nil // no more beeps
//                default:
//                    break
//                }
//            }
//            return event
//        }
//    }
    
}

struct ClipboardGroupView: View {
    var group: ClipboardGroup
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    
    @Binding var isGroupSelected: Bool
    
    @State private var imageSizeMultiple: CGFloat = 0.7
        
    @State private var showingDeleteAlert = false
    
    @State private var selectedItem: ClipboardItem?
    
    @State private var isGroupExpanded: Bool = false
    
    var body: some View {
        HStack {
            VStack {
                
                // this is the row of the group
                HStack {
                    
                    Button(action: {
                        isGroupExpanded.toggle()
                        isGroupSelected = true
                    }) {
                        Image(systemName: isGroupExpanded ? "chevron.down.circle" : "chevron.right.circle")
                            .foregroundColor(.white)
//                            .padding()
//                            .background(Circle().fill(Color.white))
//                                            .shadow(radius: 3))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut, value: isGroupExpanded)
                    .padding(.leading, 5)
                    
                    
                    // icon view for each item in group
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -20) { // Negative spacing for overlapping
                            ForEach(Array(group.itemsArray.prefix(10).indices), id: \.self) { index in
                                let item = group.itemsArray[index]
                                itemIconView(item)
                                    .zIndex(Double(10 - index)) // Ensure the first item is on top
                                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.all, 10)
                    .padding(.leading, -10)
                    
                    Spacer()
                    Button(action: {
    //                    clipboardManager.selectedItem = item
                        clipboardManager.copySelectedItem()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Copy Item")
                    
                    Button(action: {
    //                    isSelected = true
    //                    clipboardManager.selectedItem = item
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                    }
                    .help("Delete Item")
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
                .padding(.top, 3)
                .padding(.leading, 15)
                .padding(.trailing, 15)
                .padding(.bottom, 4)
                
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(!isGroupSelected ? Color(.darkGray).opacity(0.5) : Color(.darkGray))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                )
                .contentShape(Rectangle()) // Makes the entire area tappable
                .onTapGesture(count: 2) {
                    isGroupSelected = true
                    isGroupExpanded.toggle()
                }
                .onTapGesture(count: 1) {
                    isGroupSelected = true
                }
                
                
                if isGroupExpanded {
                    ScrollViewReader { scrollView in
                        LazyVStack(spacing: 0) {
                            ForEach(group.itemsArray, id: \.self) { item in
                                ClipboardItemView(item: item, imageSizeMultiple: $imageSizeMultiple, isSelected: Binding(
                                    get: { self.clipboardManager.selectedItem == item },
                                    set: { newItem in
                                        self.clipboardManager.selectedItem = newItem ? item : nil
                                    }))
                                .id(item.objectID)
                            }
                        }
                    }
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    .padding(.top, -8)
                }
            }
        }
    }
    
    @ViewBuilder
    private func itemIconView(_ item: ClipboardItem) -> some View {
        ZStack {
            if item.type == "text", let _ = item.content {
                // text image
                ZStack {
                    RoundedRectangle(cornerRadius: 8) // Background shape with rounded corners
                        .fill(Color.white) // White fill color
                        .frame(width: 50, height: 70) // Icon size
                        .shadow(radius: 2) // Optional shadow for a slight 3D effect
                    
                    VStack {
                        Image(systemName: "doc.text") // Using SF Symbols for a document icon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30) // Size of the document symbol
                        
                        Text("TXT") // Text label for TXT
                            .font(.caption) // Smaller font size
                            .fontWeight(.semibold) // Medium weight for better visibility
                    }
                }
                .padding(.all, 10)
            }
            else if item.type == "image" || item.type == "file",
                    let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.black), lineWidth: 1)
                    )
                    .clipped()
            }
            else if item.type == "folder" || item.type == "alias", let _ = item.content {
                Image("FolderThumbnail")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            }
        }
    }
    
    
    
    private func deleteItem(item: ClipboardItem) {

        if let imageHash = item.imageHash, let filePath = item.filePath, !filePath.isEmpty {
            
//            let fileManager = FileManager.default
            
            let folderPath = clipboardManager.clipboardMonitor?.tmpFolderPath
            
            if filePath.contains(folderPath!.path()) {
                
                let items = clipboardManager.clipboardMonitor?.findItems(content: nil, type: nil, imageHash: imageHash, filePath: filePath, context: nil)
                
                // only want to delete file if its the only copy left
                if items!.count < 2 {
                    print(items!.count)
                    clipboardManager.clipboardMonitor?.deleteTmpImage(filePath: filePath)
                }
            }
        }
        
        viewContext.delete(item)
            
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
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @Binding var imageSizeMultiple: CGFloat
    
    @Binding var isSelected: Bool
        
    @State private var showingDeleteAlert = false
                
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
                else if /*item.type == "imageData" ||*/ item.type == "image" || item.type == "file", 
                                let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70 * imageSizeMultiple)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.black), lineWidth: 1)
                        )
                        .clipped()
                    
                    if /*item.type != "imageData", */let content = item.content {
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
                        .frame(height: 60 * (imageSizeMultiple * 1.2))
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
            .help("Copy Item")
            
            Button(action: {
                isSelected = true
                clipboardManager.selectedItem = item
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
            }
            .help("Delete Item")
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
        .padding(.top, 3)
        .padding(.leading, 15)
        .padding(.trailing, 15)
        .padding(.bottom, 4)
        
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(!isSelected ? Color(.darkGray).opacity(0.5) : Color(.darkGray))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        )
        .contentShape(Rectangle()) // Makes the entire area tappable
        .onTapGesture(count: 2) {
            isSelected = true
            clipboardManager.copySelectedItem()
        }
        .onTapGesture(count: 1) {
            isSelected = true
        }
        
//        .onAppear() {
//            print("Item View: 1")
//        }
    }
    
    private func deleteItem(item: ClipboardItem) {

        if let imageHash = item.imageHash, let filePath = item.filePath, !filePath.isEmpty {
            
//            let fileManager = FileManager.default
            
            let folderPath = clipboardManager.clipboardMonitor?.tmpFolderPath
            
            if filePath.contains(folderPath!.path()) {
                
                let items = clipboardManager.clipboardMonitor?.findItems(content: nil, type: nil, imageHash: imageHash, filePath: filePath, context: nil)
                
                // only want to delete file if its the only copy left
                if items!.count < 2 {
                    print(items!.count)
                    clipboardManager.clipboardMonitor?.deleteTmpImage(filePath: filePath)
                }
            }
        }
        
        viewContext.delete(item)
            
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
}

struct FlashViewModifier: ViewModifier {
    
    let duration: Double
    @State private var flash: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(flash ? 0 : 1)
            .animation(.easeOut(duration: duration)/*.repeatForever()*/, value: flash)
            .onAppear {
                withAnimation {
                    flash = true
                }
            }
    }
}

extension View {
    func flash(duration: Double = 0.75) -> some View {
        modifier(FlashViewModifier(duration: duration))
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
