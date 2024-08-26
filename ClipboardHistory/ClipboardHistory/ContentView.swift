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
        entity: ClipboardGroup.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardGroup.timeStamp, ascending: false)],
        animation: nil)
    
//    private var clipboardGroups: FetchedResults<ClipboardGroup>
    private var fetchedClipboardGroups: FetchedResults<ClipboardGroup>
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    // User Defaults:
    @State private var noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
    
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
    
    @State private var selectList: [SelectedGroup] = []
    
    private var clipboardGroups: [ClipboardGroup] {
        return clipboardManager.search(fetchedClipboardGroups: fetchedClipboardGroups, searchText: searchText, selectedTypes: selectedTypes)
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
            
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            VStack {
                
                HStack {
                    SearchBarView(searchText: $searchText)
                        .focused($isFocused)
                        .padding(.trailing, (fetchedClipboardGroups.count <= 0) ? 10 : 0)
                    
                    if fetchedClipboardGroups.count > 0 {
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
                                .frame(width: 140, height: 165)
                                .padding(.bottom, -11)
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
                                .padding(.trailing, 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(!atTopOfList ? "Scroll to Top" : "Scroll to Bottom")
                    }
                    
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
                                if index >= 0 && index < selectList.count {
                                    ClipboardGroupView(selectGroup: selectList[index], selectList: $selectList, parentShowingAlert: $showingAlert, isSearchFocused: $isSearchFocused, isSelectingCategory: $isSelectingCategory,
                                                       isGroupSelected: Binding(
                                                        get: { if index >= 0 && index < selectList.count { return self.clipboardManager.selectedGroup == selectList[index] }
                                                            else { return false } },
                                                        set: { isSelected in
                                                            if index >= 0 && index < selectList.count{
                                                                self.clipboardManager.selectedGroup = isSelected ? selectList[index] : nil
                                                            }
                                                            isFocused = false
                                                        }))
                                    .id(selectList[index].group.objectID)
                                    .animation((atTopOfList || noDuplicates) ? .default : nil, value: selectList.first?.group.objectID)
                                }
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
                            if selectList.count > 0 {
                                withAnimation() {
                                    scrollView.scrollTo(selectList.first?.group.objectID, anchor: .top)
                                    scrollToTop = false
                                    clipboardManager.selectedGroup = selectList.first
                                }
                            }
                        }
                        .onChange(of: scrollToBottom, initial: false) {
                            if selectList.count > 0 {
                                withAnimation() {
                                    scrollView.scrollTo(selectList.last?.group.objectID)
                                    scrollToBottom = false
                                    clipboardManager.selectedGroup = selectList.last
                                }
                            }
                        }
                    }
                    .padding(.top, -4)
                }
                .coordinateSpace(name: "ScrollViewArea")
                .overlay( // Adds a thin line at the top or bottom
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
                                        clipboardManager.deleteItem(item: item, viewContext: viewContext, shouldSave: true)
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
                initializeSelectList()
            }
            .onChange(of: clipboardGroups.count) { oldValue, newValue in
                if clipboardGroups.count == 1 {
                    clipboardManager.selectedGroup = selectList.first
                }
                initializeSelectList()
            }
            .onChange(of: clipboardGroups.first) { oldValue, newValue in
                // when last item gets deleted and so the count doesnt change
                if clipboardGroups.count == 1 {
                    clipboardManager.selectedGroup = selectList.first
                }
                initializeSelectList()
            }
            .onChange(of: selectList.first) { oldValue, newValue in
                // is user wants no dupes, then select the top when a new copy comes in
                if noDuplicates {
                    clipboardManager.selectedGroup = selectList.first
                }
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
        
        selectedTypes.removeAll()
        
        for item in fetchedClipboardGroups {
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
                        if !isFocused || !isSelectingCategory {
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
                case 51:
                    // Handle Command + Del
                    if event.modifierFlags.contains(.command) {
                        if !isFocused || !isSelectingCategory {
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
                            isSelectingCategory = false
                            isFocused = true
                        }
                         return nil // no more beeps
                    }
                case 53:
                    // Escape key
                    DispatchQueue.main.async {
                        if isFocused == false && isSelectingCategory == false {
                            searchText = ""
                        }
                        else {
                            isSelectingCategory = false
                            isFocused = false
                        }
                    }
                    return nil
                case 126:
                    // Handle up arrow
                    isFocused = false
                    isSelectingCategory = false
                    
                    if event.modifierFlags.contains(.command) {
                        scrollToTop = true
                    }
                    else {
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
                                }
                            }
                        }
                    }
                    return nil //no more beeps
                case 125:
                    // Handle down arrow
                    isFocused = false
                    isSelectingCategory = false
                    
                    if event.modifierFlags.contains(.command) {
                        scrollToBottom = true
                    }
                    else {
                        if let currIndex = currentIndex, currIndex < selectList.count - 1 {
                            let currGroup = selectList[currIndex]
                            if currGroup.isExpanded {
                                if let selectedItem = clipboardManager.selectedItem {
                                    if let currItemIndex = currGroup.group.itemsArray.firstIndex(where: { $0 == selectedItem }),
                                       currItemIndex + 1 < currGroup.group.itemsArray.count {
                                        clipboardManager.selectedItem = currGroup.group.itemsArray[currItemIndex + 1]
                                    } else {
                                        if currIndex + 1 < selectList.count {
                                            clipboardManager.selectedGroup = selectList[currIndex + 1]
                                            clipboardManager.selectedItem = nil
                                        }
                                    }
                                } else {
                                    clipboardManager.selectedItem = currGroup.group.itemsArray.first
                                }
                            } else {
                                if currIndex + 1 < selectList.count {
                                    clipboardManager.selectedGroup = selectList[currIndex + 1]
                                    clipboardManager.selectedItem = nil
                                }
                            }
                        }
                        else if let currIndex = currentIndex {
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
                                }
                            }
                        }
                    }
                    return nil
                case 123:
//                    print("left arrow")
                    
                    isFocused = false
                    isSelectingCategory = false
                    
                    if clipboardManager.selectedGroup?.isExpanded == true {
                        if clipboardManager.selectedItem != nil {
                            clipboardManager.selectedItem = nil
                            return nil
                        }
                        else if let selectedGroup = clipboardManager.selectedGroup {
                            clipboardManager.contract(for: selectedGroup)
                            return nil
                        }
                    }
                case 115, 116:
                    // Handle Home or Page Up Key action
                    scrollToTop = true
                    return nil
                case 119, 121:
                    // Handle End or Page Down Key action
                    scrollToBottom = true
                    return nil
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
    @Binding var isSelectingCategory: Bool
    
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
                .fill((clipboardManager.selectedGroup == selectGroup && clipboardManager.selectedItem == nil) ? (isGroupSelected ? Color(.darkGray) : Color(.darkGray).opacity(0.5)) : Color(.darkGray).opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            )
//            .onTapGesture(count: 2) {
//                isGroupSelected = true
//                clipboardManager.selectedGroup = selectGroup
//                clipboardManager.copySingleGroup()
//            }
//            .onTapGesture(count: 1) {
//                print("Single Group tap:")
//                print("shouldSelectGroup: \(shouldSelectGroup)")
//                isGroupSelected = true
//                clipboardManager.selectedGroup = selectGroup
//            }
            .onAppear {
                setUpKeyboardHandling()
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
                                ForEach(Array(group.itemsArray.prefix(3).indices), id: \.self) { index in
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
                                        clipboardManager.deleteItem(item: item, viewContext: viewContext, shouldSave: true)
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
                        isGroupSelected = true
                        clipboardManager.selectedGroup = selectGroup
                        clipboardManager.selectedItem = nil
                    }
                    .onChange(of: clipboardManager.selectedGroup?.isExpanded) {
                        if clipboardManager.selectedGroup?.isExpanded == false {
                            clipboardManager.selectedItem = nil
                        }
                    }
                    
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
            // NOT NEEDED ANYMORE *** visually unselects the group when selecting its items ***
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
                        .scaledToFill()
                        .frame(maxWidth: 80, maxHeight: 60, alignment: .center)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.black), lineWidth: 1)
                        )
                        .clipped()
                    
            }
            else if item.type == "zipFile" || item.type == "dmgFile" || item.type == "randomFile" {
                switch item.type {
                case "zipFile":
                    Image("ZipFileThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 49)
                case "dmgFile":
                    Image("DmgFileThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 49)
                case "randomFile":
                    Image("RandomFileThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 49)
                default:
                    Image("RandomFileThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 49)
                }
            }
            else if item.type == "folder", let content = item.content {
                if content == "/" {
                    //main drive
                    Image("HardDriveThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                }
                else {
                    Image("FolderThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                }
            }
            else if item.type == "alias", let content = item.content {
                if content == "/" {
                    //main drive
                    Image("HardDriveThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                }
                else {
                    if item.imageData == nil {
                        Image("AliasFolderThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    }
                    else if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
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
                }
            }
            else if item.type == "removable", let _ = item.content {
                Image("DiskThumbnail")
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
                        isSearchFocused = false
                        isSelectingCategory = false
                        if !isSearchFocused || !isSelectingCategory {
                            if currSelectGroup.group.count > 1 {
                                clipboardManager.expand(for: currSelectGroup)
                                return nil
                            }
                        }
                    case 123:
                        // left arrow to contract group
                        isSearchFocused = false
                        isSelectingCategory = false
                        
                        // works like apple folder list view now
                        if !isSearchFocused || !isSelectingCategory {
                            if currSelectGroup.group.count > 1 {
                                if clipboardManager.selectedGroup?.isExpanded == true {
                                    if clipboardManager.selectedItem != nil {
                                        clipboardManager.selectedItem = nil
                                        return nil
                                    }
                                    else if let selectedGroup = clipboardManager.selectedGroup {
                                        clipboardManager.contract(for: selectedGroup)
                                        return nil
                                    }
                                }
                            }
                        }
                    case 36, 76:
                        // Handle Enter or Return
                        if !isSearchFocused || !isSelectingCategory {
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
                else if item.type == "image" || item.type == "file",
                                let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 70 * imageSizeMultiple)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.black), lineWidth: 1)
                        )
                        .clipped()
                    
                    if let content = item.content {
                        Text(content)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                }
                else if item.type == "zipFile" || item.type == "dmgFile" || item.type == "randomFile" {
                    switch item.type {
                    case "zipFile":
                        Image("ZipFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 49)
                    case "dmgFile":
                        Image("DmgFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 49)
                    default:
                        Image("RandomFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 49)
                    }
                    if let content = item.content {
                        Text(content)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                }
                else if item.type == "folder", let content = item.content {
                    if content == "/" {
                        //main drive
                        Image("HardDriveThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 49)
                        Text("Macintosh HD")
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                    else {
                        Image("FolderThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 49)
                        Text(content)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                }
                else if item.type == "alias", let content = item.content {
                    if content == "/" {
                        //main drive
                        Image("HardDriveThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 49)
                        Text("Macintosh HD")
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                    else {
                        if item.imageData == nil {
                            Image("AliasFolderThumbnail")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 49)
                            Text(content)
                                .font(.subheadline)
                                .bold()
                                .lineLimit(1)
                        }
                        else if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
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
                            Text(content)
                                .font(.subheadline)
                                .bold()
                                .lineLimit(1)
                        }
                    }
                }
                else if item.type == "removable", let content = item.content {
                    Image("DiskThumbnail")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 49)
                    Text(content)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                }
            }
            .padding(.all, 10)
           
            Spacer()
            
            if let filePath = item.filePath {
                if item.type == "alias" {
                    if let resolvedUrl = clipboardManager.clipboardMonitor?.resolveAlias(fileUrl: URL(fileURLWithPath: filePath)),
                       let resourceValues = try? resolvedUrl.resourceValues(forKeys: [.isDirectoryKey, .isAliasFileKey]) {
                        
                        if resourceValues.isAliasFile == true || resourceValues.isDirectory == true {
                            Button(action: {
                                self.openFolder(filePath: resolvedUrl.path)
                            }) {
//                                Image(systemName: "rectangle.portrait.and.arrow.right")
//                                    .foregroundColor(.white)
                                Image(systemName: "folder")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 5)
                            .help("Open Folder")
                        } else {
                            Button(action: {
                                self.openFile(filePath: resolvedUrl.path)
                            }) {
//                                Image(systemName: "rectangle.portrait.and.arrow.right")
//                                    .foregroundColor(.white)
                                Image(systemName: "folder")
                                    .foregroundColor(.white)

                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 5)
                            .help("Open File")
                        }
                    }
                } else if let type = item.type, type == "folder" || type == "removable" || type == "zipFile" || type == "dmgFile" || type == "randomFile" {
                    Button(action: {
                        self.openFolder(filePath: filePath)
                    }) {
//                        Image(systemName: "rectangle.portrait.and.arrow.right")
//                            .foregroundColor(.white)
                        Image(systemName: "folder")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 5)
                    .help("Open \(type.contains("file") ? "File" : "Folder")")
                } else if item.type == "file" || item.type == "image" {
                    Button(action: {
                    self.openFile(filePath: filePath)
                    }) {
//                        Image(systemName: "rectangle.portrait.and.arrow.right")
//                            .foregroundColor(.white)
                        Image(systemName: "folder")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 5)
                    .help("Open \(item.type == "image" ? "Image" : "File")")
                }
            }
            
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
                            clipboardManager.deleteItem(item: item, viewContext: viewContext, shouldSave: true)
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
            if isPartOfGroup {
                clipboardManager.selectedItem = item
            }
            else {
                clipboardManager.selectedItem = nil
            }
        }
    }
    
    private func openFolder(filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    private func openFile(filePath: String) {
        // if file is tmp image, copy to desktop, then open
            // else, open the file
        
        
        let fileURL = URL(fileURLWithPath: filePath)
        let fileName = fileURL.lastPathComponent
        
        let regexPattern = "^Image \\d{4}-\\d{2}-\\d{2} at \\d{1,2}\\.\\d{2}\\.\\d{2} (AM|PM)\\.png$"
        
        do {
            let regex = try NSRegularExpression(pattern: regexPattern)
            let range = NSRange(location: 0, length: fileName.utf16.count)
            
            if regex.firstMatch(in: fileName, options: [], range: range) != nil && fileURL.path.hasPrefix(clipboardManager.clipboardMonitor?.tmpFolderPath.path ?? "") {
                                // File matches the regex pattern, copy it to the desktop
                let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                let destinationURL = desktopURL.appendingPathComponent(fileName)
                
                
                do {
                    try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                    print("File copied to Desktop: \(destinationURL.path)")
                    // Check if the file exists and open it
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        NSWorkspace.shared.open(destinationURL)
                    } else {
                        print("File does not exist at path: \(destinationURL.path)")
                    }
                } catch {
                    print("Failed to copy file to Desktop: \(error)")
                }
            }
            else {
                // Check if the file exists and open it
                if FileManager.default.fileExists(atPath: filePath) {
                    NSWorkspace.shared.open(fileURL)
                } else {
                    print("File does not exist at path: \(filePath)")
                }
            }
        } catch {
            print("Invalid regex pattern: \(error)")
        }
    }
}

struct FlashViewModifier: ViewModifier {
    
    let duration: Double
    @State private var flash: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(flash ? 0 : 1)
            .animation(.easeOut(duration: duration), value: flash)
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
