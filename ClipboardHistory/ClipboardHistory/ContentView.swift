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
    
//    var selectList: [SelectedGroup] {
//        clipboardGroups.map { group in
//            SelectedGroup(group: group, selectedItem: nil)
//        }
//    }
    @State private var selectList: [SelectedGroup] = []


        
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
//                            ForEach(clipboardGroups, id: \.self) { group in
//                                ClipboardGroupView(group: group, selectList: selectList,
//                                   isGroupSelected: Binding(
//                                        get: { self.clipboardManager.selectedGroup == group.GetSelecGroupObj(group, list: selectList) },
//                                        set: { isSelected in
//                                            self.clipboardManager.selectedGroup = isSelected ? group.GetSelecGroupObj(group, list: selectList) : nil
//                                            isFocused = false
//                                        }))
//                                .id(group.GetSelecGroupObj(group, list: selectList)?.group.objectID)
//                            }
                            
                            ForEach(selectList.indices, id: \.self) { index in
                                ClipboardGroupView(group: $selectList[index].group,
                                   isGroupSelected: Binding(
                                    get: { self.clipboardManager.selectedGroup == selectList[index] },
                                    set: { isSelected in
                                        self.clipboardManager.selectedGroup = isSelected ? selectList[index] : nil
                                        isFocused = false
                                    }))
                                .id(selectList[index].group.objectID)
                            }
                        } //scrolls when using the arrow keys
                        .onChange(of: clipboardManager.selectedGroup, initial: false) {
                            if let selectedGroup = clipboardManager.selectedGroup, let index = selectList.firstIndex(of: selectedGroup) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollView.scrollTo(selectList[index].group.objectID)
                                }
//                                print("\(index) ***")
//                                if selectedGroup.group.count == 1 {
//                                    clipboardManager.selectedItem = selectedGroup.group.itemsArray.first
//                                    clipboardManager.selectedGroup?.selectedItem = clipboardManager.selectedItem
//                                }
                            }
                        }
//                        .onChange(of: clipboardManager.selectedItem, initial: false) {
//                            if let _ = clipboardManager.selectedItem {
//                                    clipboardManager.selectedGroup = nil
//                            }
//                         }
                        
                        .onChange(of: scrollToTop, initial: false) {
                            withAnimation() {
                                scrollView.scrollTo(selectList.first?.group.objectID, anchor: .top)
                                scrollToTop = false
                            }
                        }
                        .onChange(of: scrollToBottom, initial: false) {
                            withAnimation() {
                                scrollView.scrollTo(selectList.last?.group.objectID)
                                scrollToBottom = false
                            }
                        }
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
                .onAppear {
                    clipboardManager.selectedGroup = selectList.first
                }

            }
            .onAppear {
//                clipboardManager.selectedGroup = selectList.first
                setUpKeyboardHandling()
                self.selectList = clipboardGroups.map { SelectedGroup(group: $0, selectedItem: nil) }
            }
            .onChange(of: clipboardGroups.count) { oldValue, newValue in
                if clipboardGroups.count == 1 {
                    clipboardManager.selectedGroup = selectList.first
                }
                self.selectList = clipboardGroups.map { SelectedGroup(group: $0, selectedItem: nil) }
            }
//            .onChange(of: clipboardManager.selectedGroup?.isExpanded) { oldValue, newValue in
//                if let selectGroup = clipboardManager.selectedGroup, let index = selectList.firstIndex(where: { $0.group === selectGroup.group }) {
//                    selectList[index].isExpanded = selectGroup.isExpanded
//                }
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
    
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            var currentIndex: Int?
            if let group = clipboardManager.selectedGroup {
                currentIndex = selectList.firstIndex(of: group)
//                print("\(currentIndex)\n")
            }
            if currentIndex == nil {
                if !selectList.isEmpty {
                    clipboardManager.selectedGroup = selectList[0]
                    if let group = clipboardManager.selectedGroup?.group, group.count == 1 {
//                        print("here")
                        clipboardManager.selectedGroup?.selectedItem = clipboardManager.selectedGroup?.group.itemsArray.first
                    }
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
//                        clipboardManager.copySelectedItem()
                         return nil // no more beeps
                    }
                case 36, 76:
                    // Handle Enter or Return
                    for group in selectList {
                        print(group.isExpanded)
                    }
                    print("\n")
                    
                    if !isFocused {
//                        clipboardManager.copySelectedItem()
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
//                    print(currentIndex)
                    if let currIndex = currentIndex, currentIndex! > 0 {
                        var nextIndex = currIndex - 1
                        while nextIndex >= 0 && selectList[nextIndex].isExpanded {
                            nextIndex -= 1
                        }
                        if nextIndex >= 0 {
                            clipboardManager.selectedGroup = selectList[nextIndex]
                            //                        print( clipboardManager.selectedGroup == nil)
                        }
                    }
                     return nil //no more beeps
                case 125:
                    // Handle down arrow
                    isFocused = false
//                    print(currentIndex)

                    if let currIndex = currentIndex, currentIndex! < selectList.count - 1 {
                        var nextIndex = currIndex + 1
                        while nextIndex < selectList.count && selectList[nextIndex].isExpanded {
                            print("wut")

//                            nextIndex += 1
                            let group = selectList[nextIndex].group
                            var groupIndex = 0
                            while groupIndex < group.count && group.count > 1 {
                                print("here")
                                clipboardManager.selectedItem = selectList[nextIndex].group.itemsArray[groupIndex]
                                groupIndex += 1
                            }
                            
                            nextIndex += 1
                        }
                        if nextIndex < selectList.count {
                            print(selectList[nextIndex].isExpanded)
                            clipboardManager.selectedGroup = selectList[nextIndex]
                        }
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

struct ClipboardGroupView: View {
    @Binding var group: ClipboardGroup
//    var selectList: [SelectedGroup]
    @Binding var isGroupSelected: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @State private var imageSizeMultiple: CGFloat = 0.7
        
    @State private var showingDeleteAlert = false
    
    @State private var selectedItem: ClipboardItem?
    
    @State private var isGroupExpanded: Bool = false
    
    
    var body: some View {
        
        if group.count == 1, let item = group.itemsArray.first {
            ClipboardItemView(item: item, imageSizeMultiple: $imageSizeMultiple, isSelected: Binding(
                get: { self.clipboardManager.selectedItem == item },
                set: { newItem in
                    self.clipboardManager.selectedItem = newItem ? item : nil
//                    self.clipboardManager.selectedGroup = newItem ? group.GetSelecGroupObj(group, list: selectList) : nil
//                    if let _ = self.clipboardManager.selectedGroup {
//                        self.clipboardManager.selectedGroup?.selectedItem = newItem ? item : nil
//                    }
                    isGroupSelected = true
                }))
            .id(item.objectID)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(!isGroupSelected ? Color(.darkGray).opacity(0.5) : Color(.darkGray))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            )
            .onTapGesture(count: 2) {
                isGroupSelected = true
//                clipboardManager.copySelectedItem()
            }
            .onTapGesture(count: 1) {
                isGroupSelected = true
            }
            
        }
        else if group.count > 1 {
            
            
            HStack {
                VStack {
                    
                    // this is the row of the group
                    HStack {
                        
                        Button(action: {
                            isGroupSelected = true
                            isGroupExpanded.toggle()
                            //                            clipboardManager.selectedGroup?.isGroupExpanded.toggle()
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
                        //                        clipboardManager.selectedGroup?.isGroupExpanded.toggle()
                    }
                    .onTapGesture(count: 1) {
                        isGroupSelected = true
                    }
                    
                    
                    if isGroupExpanded {
                        ScrollViewReader { scrollView in
                            LazyVStack(spacing: 0) {
                                ForEach(group.itemsArray, id: \.self) { item in
                                    ClipboardItemView(item: item, imageSizeMultiple: $imageSizeMultiple, isSelected: Binding(
                                        get: { self.clipboardManager.selectedItem == item
                                            //                                            self.clipboardManager.selectedGroup?.selectedItem == item
                                        },
                                        set: { newItem in
                                            self.clipboardManager.selectedItem = newItem ? item : nil
                                            //                                            self.clipboardManager.selectedGroup = newItem.group ? item.group : nil
                                            //                                            self.clipboardManager.selectedGroup?.selectedItem = newItem ? item : nil
                                            
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
                .onChange(of: isGroupExpanded) {
                    isGroupExpanded = isGroupExpanded
                    clipboardManager.selectedGroup?.isExpanded = isGroupExpanded
//                    if let index = selectList.firstIndex(where: { $0.group === clipboardManager.selectedGroup?.group }) {
//                        selectList[index].isGroupExpanded = isGroupExpanded
//                    }
                }
            }
        }
        
//            .onTapGesture(count: 2) {
//                isGroupSelected = true
////                clipboardManager.copySelectedItem()
//            }
//            .onTapGesture(count: 1) {
//                isGroupSelected = true
//            }
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
//    var selectList: [SelectedGroup]
    
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
        
//        .background(RoundedRectangle(cornerRadius: 8)
//            .fill(!isSelected) ? Color(.darkGray).opacity(0.5) : Color(.darkGray))
//            .padding(.horizontal, 10)
//            .padding(.vertical, 4)
//        )
//        .contentShape(Rectangle()) // Makes the entire area tappable
//        .onTapGesture(count: 2) {
//            isSelected = true
//            clipboardManager.copySelectedItem()
//        }
//        .onTapGesture(count: 1) {
//            isSelected = true
//        }
        
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
