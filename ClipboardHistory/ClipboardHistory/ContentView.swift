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
    @State private var isSearchFocused: Bool = false
    
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
                            ForEach(selectList.indices, id: \.self) { index in
                                ClipboardGroupView(selectGroup: selectList[index], selectList: $selectList, parentShowingAlert: $showingAlert, isSearchFocused: $isSearchFocused,
                                   isGroupSelected: Binding(
                                    get: { if index >= 0 { return self.clipboardManager.selectedGroup == selectList[index] }
                                        else { return false } },
                                    set: { isSelected in
                                        if index >= 0 {
                                            self.clipboardManager.selectedGroup = isSelected ? selectList[index] : nil
                                        }
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
                            }
                        }
                        .onChange(of: clipboardManager.selectedItem, initial: false) {
                            if let selectedItem = clipboardManager.selectedItem {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollView.scrollTo(selectedItem.objectID)
                                }
                            }
                            else {
                                if let selectedGroup = clipboardManager.selectedGroup, let index = selectList.firstIndex(of: selectedGroup) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            scrollView.scrollTo(selectList[index].group.objectID, anchor: (selectedGroup.isExpanded && clipboardManager.selectedItem == nil) ? .top : nil)
                                        }
                                }
                            }
                        }
                        
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
                                if let item = clipboardManager.selectedItem {
                                        clipboardManager.deleteItem(item: item, viewContext: viewContext, isCalledByGroup: false)
                                }
                                else {
                                    clipboardManager.deleteGroup(group: clipboardManager.selectedGroup?.group, selectList: selectList, viewContext: viewContext)
                                }
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
                clipboardManager.selectedGroup = selectList.first
                setUpKeyboardHandling()
//                self.selectList = clipboardGroups.map { SelectedGroup(group: $0) }
                initializeSelectList()
            }
            .onChange(of: clipboardGroups.count) { oldValue, newValue in
                if clipboardGroups.count == 1 {
                    clipboardManager.selectedGroup = selectList.first
                }
//                self.selectList = clipboardGroups.map { SelectedGroup(group: $0) }
                initializeSelectList()
            }
            .onChange(of: clipboardGroups.first) { oldValue, newValue in
                // when last item gets deleted and so the count doesnt change
                if clipboardGroups.count == 1 {
                    clipboardManager.selectedGroup = selectList.first
                }
//                self.selectList = clipboardGroups.map { SelectedGroup(group: $0) }
                initializeSelectList()
            }
            .onChange(of: isFocused) {
                isSearchFocused = isFocused
            }
        }
    }
    
    func initializeSelectList() {
        self.selectList = clipboardGroups.map { clipboardGroup in
            let isExpanded = self.findExpandedState(for: clipboardGroup)
            return SelectedGroup(group: clipboardGroup, isExpanded: isExpanded)
        }
    }
    
    func findExpandedState(for inputGroup: ClipboardGroup) -> Bool {
        // if this group was already in selectList, return its isExpanded
        return selectList.first(where: { $0.group == inputGroup })?.isExpanded ?? false
    }
    
    private func clearClipboardItems() {
        clipboardManager.clipboardMonitor?.clearTmpImages()
        
        for item in clipboardGroups {
            viewContext.delete(item)
        }
        clipboardManager.selectedGroup = nil
        clipboardManager.selectedItem = nil
        
        do {
            try viewContext.save()
        } catch let error {
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
                        if !isFocused {
                            // Handle Command + C
                            if clipboardManager.selectedItem != nil {
                                clipboardManager.copySelectedItemInGroup()
                                return nil
                            }
                            else {
                                clipboardManager.copySelectedGroup()
                                return nil
                            }
                        }
                    }
                    
//                case 36, 76:
//                    // Handle Enter or Return
//                    for group in selectList {
//                        print(group.isExpanded)
//                    }
//                    print("\n")
//                    
//                    if !isFocused {
////                        clipboardManager.copySelectedItem()
//                         return nil // no more beeps
//                    }
                case 51:
                    // Handle Command + Del
                    if event.modifierFlags.contains(.command) {
                        if !isFocused {
                            DispatchQueue.main.async {
                                self.showingAlert = true
                                activeAlert = .delete
                            }
                            return nil
                        }
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

                    if let currIndex = currentIndex, currIndex - 1 >= 0 {
                        
                        let aboveGroup = selectList[currIndex - 1]
                        let currGroup = selectList[currIndex]
                        
                        
                        if currGroup.isExpanded {
                            if let selectedItem = clipboardManager.selectedItem {
                                if let itemIndex = currGroup.group.itemsArray.firstIndex(where: { $0 == selectedItem }) {
                                    if itemIndex == 0 {
                                        clipboardManager.selectedItem = nil
                                        clipboardManager.selectedGroup = currGroup
                                    }
                                    else if itemIndex - 1 >= 0 {
                                        clipboardManager.selectedItem = currGroup.group.itemsArray[itemIndex - 1]
                                    }
                                } else {
                                    print("*** idk ***")
//                                    if currIndex - 1 >= 0 {
//                                        clipboardManager.selectedGroup = selectList[currIndex - 1]
//                                        clipboardManager.selectedItem = nil
//                                    }
                                }
                            }
                            // group is expanded, but at the top of the current group
                            else {
                                clipboardManager.selectedGroup = aboveGroup
                                if aboveGroup.isExpanded {
                                    clipboardManager.selectedItem = aboveGroup.group.itemsArray.last
                                }
                                else {
                                    clipboardManager.selectedItem = nil
                                }
                            }
                        }
                        // current group isnt expanded, so lets go to the next group up, but how? ...
                        else {
                            clipboardManager.selectedGroup = aboveGroup
                            
                            if !aboveGroup.isExpanded {
//                                print("not group")
                                //                            clipboardManager.selectedGroup = aboveGroup
                                clipboardManager.selectedItem = nil
                            }
                            else if aboveGroup.isExpanded {
                                clipboardManager.selectedItem = aboveGroup.group.itemsArray.last
                            }
                        }
                    }
                    else if let currIndex = currentIndex {
                        // at the top of the selectList, but group is expanded
                        
                        let currGroup = selectList[currIndex]
                        
                        if currGroup.isExpanded {
                            if let selectedItem = clipboardManager.selectedItem {
                                if let itemIndex = currGroup.group.itemsArray.firstIndex(where: { $0 == selectedItem }) {
                                    if itemIndex == 0 {
                                        clipboardManager.selectedItem = nil
                                        clipboardManager.selectedGroup = currGroup
                                    }
                                    else if itemIndex - 1 >= 0 {
                                        clipboardManager.selectedItem = currGroup.group.itemsArray[itemIndex - 1]
                                    }
                                }
                                //                                else {
                                //                                    print("*** idk ***")
                                ////                                    if currIndex - 1 >= 0 {
                                ////                                        clipboardManager.selectedGroup = selectList[currIndex - 1]
                                ////                                        clipboardManager.selectedItem = nil
                                ////                                    }
                                //                                }
                            }
                            
                        }
                        
                    }
                    return nil //no more beeps
                case 125:
                    // Handle down arrow
                    isFocused = false
                    print( )
                    if let currIndex = currentIndex, currIndex < selectList.count - 1 {
                        print("a")
                        
                        let currGroup = selectList[currIndex]
                        if currGroup.isExpanded {
                            print("b")
                            if let selectedItem = clipboardManager.selectedItem {
                                print("c")
                                if let currItemIndex = currGroup.group.itemsArray.firstIndex(where: { $0 == selectedItem }),
                                        currItemIndex + 1 < currGroup.group.itemsArray.count {
                                    print("d")
                                    clipboardManager.selectedItem = currGroup.group.itemsArray[currItemIndex + 1]
                                } else {
                                    print("e")
                                    if currIndex + 1 < selectList.count {
                                        print("f")
                                        clipboardManager.selectedGroup = selectList[currIndex + 1]
                                        clipboardManager.selectedItem = nil
                                    }
                                }
                            } else {
                                print("g")
                                clipboardManager.selectedItem = currGroup.group.itemsArray.first
//                                clipboardManager.selectedGroup = currGroup
                            }
                        } else {
                            print("h")
                            if currIndex + 1 < selectList.count {
                                clipboardManager.selectedGroup = selectList[currIndex + 1]
                                clipboardManager.selectedItem = nil
                                print(clipboardManager.selectedGroup?.group.itemsArray.first?.content ?? "null")
                                print(clipboardManager.selectedItem?.content ?? "dne")
                                print(clipboardManager.selectedGroup?.group.count ?? 69)
                            }
                        }
                    }
                    else if let currIndex = currentIndex {
                        print("i")
                        // at bottom of selectList, but group is expanded
                        let currGroup = selectList[currIndex]
                        if currGroup.isExpanded {
                            if let selectedItem = clipboardManager.selectedItem {
                                if let currItemIndex = currGroup.group.itemsArray.firstIndex(where: { $0 == selectedItem }),
                                        currItemIndex + 1 < currGroup.group.itemsArray.count {
                                    clipboardManager.selectedItem = currGroup.group.itemsArray[currItemIndex + 1]
                                } 
                                else {
                                    if currIndex + 1 < selectList.count {
                                        clipboardManager.selectedGroup = selectList[currIndex + 1]
                                        clipboardManager.selectedItem = nil
                                    }
                                }
                            } 
                            else {
                                clipboardManager.selectedItem = currGroup.group.itemsArray.first
//                                clipboardManager.selectedGroup = currGroup
                            }
                        }
                    }
                    print( )
                    return nil
//                case 123:
//                    isFocused = false
//
//                    print("left arrow")
//                    if let currIndex = currentIndex, currIndex < selectList.count - 1 {
//
//                        let currGroup = selectList[currIndex]
//                        clipboardManager.selectedGroup = currGroup
//                    }
//
//                    return nil
                default:
                    break
                }
            }
            return event
        }
    }
    
}

struct ClipboardGroupView: View {

    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var selectGroup: SelectedGroup
    @Binding var selectList: [SelectedGroup]
    
    @Binding var parentShowingAlert: Bool
    
    @Binding var isSearchFocused: Bool
    
    @Binding var isGroupSelected: Bool
        
    @State private var imageSizeMultiple: CGFloat = 0.7
        
    @State private var showingDeleteAlert = false
        
//    @State private var isGroupExpanded: Bool = false
    
    @State private var shouldSelectGroup: Bool = true
    
    
    var body: some View {
        let group = selectGroup.group
        if group.count == 1, let item = group.itemsArray.first {
            ClipboardItemView(item: item, selectGroup: selectGroup, selectList: $selectList, isPartOfGroup: false, imageSizeMultiple: $imageSizeMultiple, isSelected: Binding(
                get: { self.clipboardManager.selectedItem == item },
                set: { newItem in
                    isGroupSelected = true
                    self.clipboardManager.selectedGroup = selectGroup
                }))
            .id(item.objectID)
            .background(RoundedRectangle(cornerRadius: 8)
//                .fill(shouldSelectGroup ? (isGroupSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5)) : Color(.darkGray).opacity(0.5))
                .fill((clipboardManager.selectedGroup == selectGroup && clipboardManager.selectedItem == nil) ? (isGroupSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5)) : Color(.darkGray).opacity(0.5))
//                .fill(isGroupSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            )
//            .onTapGesture(count: 2) {
//                isGroupSelected = true
//                clipboardManager.selectedGroup = selectGroup
//                clipboardManager.copySingleGroup()
//            }
            .onTapGesture(count: 1) {
                print("Single Group tap:")
                print("shouldSelectGroup: \(shouldSelectGroup)")
//                isGroupSelected = true
//                clipboardManager.selectedGroup = selectGroup
            }
        }
        else if group.count > 1 {
            
            
            HStack {
                VStack {
                    
                    // this is the row of the group
                    HStack {
                        
                        Button(action: {
                            isGroupSelected = true
                            clipboardManager.selectedGroup = selectGroup
                            clipboardManager.toggleExpansion(for: selectGroup)
                        }) {
                            Image(systemName: selectGroup.isExpanded ? "chevron.down.circle" : "chevron.right.circle")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut, value: selectGroup.isExpanded)
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
                            isGroupSelected = true
                            clipboardManager.selectedGroup = selectGroup
                            clipboardManager.copySelectedGroup()
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Copy Item")
                        
                        Button(action: {
                            isGroupSelected = true
                            clipboardManager.selectedGroup = selectGroup
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
                                    if let item = clipboardManager.selectedItem {
                                        clipboardManager.deleteItem(item: item, viewContext: viewContext, isCalledByGroup: false)
                                    }
                                    else {
                                        clipboardManager.deleteGroup(group: clipboardManager.selectedGroup?.group, selectList: selectList, viewContext: viewContext)
                                    }
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
//                        .fill(shouldSelectGroup ? (isGroupSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5)) : Color(.darkGray).opacity(0.5))
                        .fill((clipboardManager.selectedGroup == selectGroup && clipboardManager.selectedItem == nil) ? (isGroupSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5)) : Color(.darkGray).opacity(0.5))

                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    )
                    .contentShape(Rectangle()) // Makes the entire area tappable
                    .onTapGesture(count: 2) {
                        isGroupSelected = true
                        clipboardManager.selectedGroup = selectGroup
                        clipboardManager.copySelectedGroup()
                    }
                    .onTapGesture(count: 1) {
                        print("Group Top Tapp:")
                        print("shouldSelectGroup: \(shouldSelectGroup)")
                        isGroupSelected = true
                        clipboardManager.selectedGroup = selectGroup
                        clipboardManager.selectedItem = nil
                    }
                    .onChange(of: clipboardManager.selectedGroup?.isExpanded) {
                        if clipboardManager.selectedGroup?.isExpanded == false {
                            clipboardManager.selectedItem = nil
                        }
                    }
                    
                    
//                    if /*let currSelectGroup = clipboardManager.selectedGroup, currSelectGroup.isExpanded ||*/ isGroupExpanded {
                    if selectGroup.isExpanded {
                        ScrollViewReader { scrollView in
                            LazyVStack(spacing: 0) {
                                ForEach(group.itemsArray, id: \.self) { item in
                                    ClipboardItemView(item: item, selectGroup: selectGroup, selectList: $selectList, isPartOfGroup: true, imageSizeMultiple: $imageSizeMultiple, isSelected: Binding(
                                        get: { self.clipboardManager.selectedItem == item
                                        },
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
            .onAppear {
                setUpKeyboardHandling()
            }
            // *** visually unselects the group when selecting its items ***
//            .onChange(of: clipboardManager.selectedItem) {
//                if let item = clipboardManager.selectedItem, let itemGroup = item.group, let group = clipboardManager.selectedGroup?.group,
//                   itemGroup == group {
//                        shouldSelectGroup = false
//                }
//                else {
//                    shouldSelectGroup = true
//                }
//            }
        }
    }
    
    @ViewBuilder
    private func itemIconView(_ item: ClipboardItem) -> some View {
        ZStack {
            if item.type == "text", let _ = item.content {
                // text image
                ZStack { // haven't tested this yet!!
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 50, height: 70)
                        .shadow(radius: 2)
                    
                    VStack {
                        Image(systemName: "doc.text")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                        
                        Text("TXT")
                            .font(.caption)
                            .fontWeight(.semibold)
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
    
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            
            if let currSelectGroup = clipboardManager.selectedGroup {
                
                if event.type == .keyDown && !parentShowingAlert {
                    switch event.keyCode {
                    case 124:
                        // right arrow to expand group
                        if currSelectGroup.group.count > 1 {
                            clipboardManager.expand(for: currSelectGroup)
                            return nil
                        }
                    case 123:
                        // left arrow to contract group
                        if currSelectGroup.group.count > 1 {
                            clipboardManager.contract(for: currSelectGroup)
                            return nil
                        }
                    case 36, 76:
                        // Handle Enter or Return
                        if !isSearchFocused {
                            if clipboardManager.selectedItem != nil {
                                clipboardManager.copySelectedItemInGroup()
                                return nil
                            }
                            else {
                                clipboardManager.copySelectedGroup()
                                return nil
                            }
                        }
                    default:
                        break
                    }
                }
            }
            return event
        }
    }
}


struct ClipboardItemView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var item: ClipboardItem
    
    var selectGroup: SelectedGroup
    
    @Binding var selectList: [SelectedGroup]
    
    var isPartOfGroup: Bool
    
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
                        .frame(height: 49/*isPartOfGroup ? 60 : 49*/)
                    Text(content)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                }
            }
            .padding(.all, 10)
           
            Spacer()
            Button(action: {
                clipboardManager.selectedGroup = selectGroup
                if isPartOfGroup {
                    clipboardManager.selectedItem = item
                    clipboardManager.copySelectedItemInGroup()
                }
                else {
                    clipboardManager.copySingleGroup()
                }
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.white)
            }
            .buttonStyle(BorderlessButtonStyle())
            .help("Copy Item")
            
            Button(action: {
                isSelected = true
                if isPartOfGroup {
                    clipboardManager.selectedItem = item
                }
                clipboardManager.selectedGroup = selectGroup
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
                        if let item = clipboardManager.selectedItem {
                            clipboardManager.deleteItem(item: item, viewContext: viewContext, isCalledByGroup: false)
                        }
                        else {
                            clipboardManager.deleteGroup(group: clipboardManager.selectedGroup?.group, selectList: selectList, viewContext: viewContext)
                        }
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
            .fill(isPartOfGroup ? (isSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5)) : Color.clear)
//            .fill(isSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        )
        .contentShape(Rectangle()) // Makes the entire area tappable
        .onTapGesture(count: 2) {
            isSelected = true
            clipboardManager.selectedGroup = selectGroup
            if isPartOfGroup {
                clipboardManager.selectedItem = item
                clipboardManager.copySelectedItemInGroup()
            }
            else {
                clipboardManager.copySingleGroup()
            }
        }
        .onTapGesture(count: 1) {
            isSelected = true
            clipboardManager.selectedGroup = selectGroup
            print("Item View tapp:")
            print("isPartOfGroup: \(isPartOfGroup)")
            print(clipboardManager.selectedGroup?.group.itemsArray.first?.content ?? "nullll")
            print(clipboardManager.selectedItem?.content ?? "nulllll")
            print( )
            
            if isPartOfGroup {
                clipboardManager.selectedItem = item
            }
            else {
                clipboardManager.selectedItem = nil
            }
        }
//        .onChange(of: group.count) {
//            if group.count == 1 {
//                shouldSelectGroup = false
//            }
//        }
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
