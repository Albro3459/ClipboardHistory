//
//  ContentView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/13/24.
//

import SwiftUI
import CoreData
import KeyboardShortcuts
import Combine

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
    
    let userDefaultsManager = UserDefaultsManager.shared
    let menuManager = MenuManager.shared
        
    @State private var showingAlert = false
    @State private var groupShowingAlert = false
    @State private var activeAlert: ActiveAlert = .clear

    @State private var atTopOfList = true
            
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    @State private var isSearchFocused: Bool = false
    
    @State private var isSelectingCategory: Bool = false
    @State private var selectedTypes: Set<UUID> = []
    
    @State private var scrollToTop: Bool = false
    @State private var scrollToBottom: Bool = false
    @State private var justScrolledToTop: Bool = true
    
    @State private var imageSizeMultiple: CGFloat = 1
    
    @State private var copyStatusChanged: Bool = false    
    @State private var showCopyFailedFeedback: Bool = false
    
    @State private var windowWidth: CGFloat = 0
    @State private var windowHeight: CGFloat = 0
    
    @State private var selectList: [SelectedGroup] = []
    
    private var clipboardGroups: [ClipboardGroup] {
        return clipboardManager.search(fetchedClipboardGroups: fetchedClipboardGroups, searchText: searchText, selectedTypes: selectedTypes)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        self.windowWidth = geometry.size.width
                        self.windowHeight = geometry.size.height
                    }
                    .onChange(of: geometry.size.width) { old, new in
                        self.windowWidth = new
                    }
                    .onChange(of: geometry.size.height) { old, new in
                        self.windowHeight = new
                    }
            }
            .zIndex(-10)
            
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
                            .foregroundColor(UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray)
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray)
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
                // x: frame_width/2  |  y: -(window_height/2 - frame_height)
                .position(x: 90/2, y: -(self.windowHeight/2 - 24))
                .frame(width: 90, height: 24)
                .zIndex(5)
            
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            if self.copyStatusChanged, let monitor = clipboardManager.clipboardMonitor {
                ZStack(alignment: .center) {
                    
                    ZStack(alignment: .top) {
                        Rectangle()
                            .foregroundColor(UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray)
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray)
                            .frame(height: 10)
                            .zIndex(1)
                    }
                    Text("Copying \(monitor.isCopyingPaused ? "Paused" : "Resumed")!")
                        .font(.subheadline)
                        .bold()
                        
                        .cornerRadius(8)
                        .frame(alignment: .center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: monitor.isCopyingPaused)
                // x: frame_width/2  |  y: -(window_height/2 - frame_height)
                .position(x: (monitor.isCopyingPaused ? 110 : 120)/2, y: -(self.windowHeight/2 - 24))
                .frame(width: (monitor.isCopyingPaused ? 110 : 120), height: 24)
                .zIndex(5)
            
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            // when copying fails due to copying being paused
            if let monitor = clipboardManager.clipboardMonitor, self.showCopyFailedFeedback || monitor.showCopyFailedFeedback {
                ZStack(alignment: .center) {
                    
                    ZStack(alignment: .top) {
                        Rectangle()
                            .foregroundColor(Color(.red))
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(Color(.red))
                            .frame(height: 10)
                            .zIndex(1)
                    }
                    Text("Copying is Paused!")
                        .font(.subheadline)
                        .bold()
                        .cornerRadius(8)
                        .frame(alignment: .center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: self.showCopyFailedFeedback)
                // x: frame_width/2  |  y: -(window_height/2 - frame_height)
                .position(x: 120/2, y: -(self.windowHeight/2 - 24) )
                .frame(width: 120, height: 24)
                .zIndex(5)
            
                
                Color.red.opacity(0.1).flash(duration: 0.3)
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
                                .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
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
                            if !atTopOfList && !justScrolledToTop {
                                scrollToTop = true
                                justScrolledToTop = true
                            }
                            else if atTopOfList || justScrolledToTop {
                                scrollToBottom = true
                                justScrolledToTop = false
                            }
                        }) {
                            Image(systemName: (!atTopOfList && !justScrolledToTop) ? "arrow.up.circle" : "arrow.down.circle")
                                .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                                .padding(.trailing, 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(!atTopOfList && !justScrolledToTop ? "Scroll to Top" : "Scroll to Bottom")
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
                                    ClipboardGroupView(selectGroup: selectList[index], selectList: $selectList, parentShowingAlert: $showingAlert, groupShowingAlert: $groupShowingAlert, isSearchFocused: $isSearchFocused, isSelectingCategory: $isSelectingCategory, windowWidth: $windowWidth,
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
                                    .animation((atTopOfList || userDefaultsManager.noDuplicates) ? .default : nil, value: selectList.first?.group.objectID)
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
//                                    }
                                }
                            }
                        }
                        
                        .onChange(of: scrollToTop, initial: false) {
                            if selectList.count > 0 {
                                withAnimation() {
                                    scrollView.scrollTo(selectList.first?.group.objectID, anchor: .top)
                                    scrollToTop = false
                                    justScrolledToTop = true
                                    clipboardManager.selectedGroup = selectList.first
                                }
                            }
                        }
                        .onChange(of: scrollToBottom, initial: false) {
                            if selectList.count > 0 {
                                withAnimation() {
                                    scrollView.scrollTo(selectList.last?.group.objectID)
                                    scrollToBottom = false
                                    justScrolledToTop = false
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
//            .onChange(of: fetchedClipboardGroups)
            .onChange(of: clipboardGroups.count) { oldValue, newValue in
                print("change to clipboardGroups Count!!")
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
                if userDefaultsManager.noDuplicates {
                    clipboardManager.selectedGroup = selectList.first
                }
            }
            .onChange(of: isFocused) {
                isSearchFocused = isFocused
            }
            .onReceive(clipboardManager.clipboardMonitor?.copyFailedStateChange ?? PassthroughSubject<Void, Never>()) { _ in
                // needed because this change wont update unless app is active
                if let monitor = clipboardManager.clipboardMonitor {
                    self.showCopyFailedFeedback = monitor.showCopyFailedFeedback
                }
            }
            .onReceive(clipboardManager.clipboardMonitor?.copyStatusStateChange ?? PassthroughSubject<Void, Never>()) { _ in
                // needed because this change wont update unless app is active
                if let monitor = clipboardManager.clipboardMonitor {
//                    let status = monitor.isCopyingPaused
//                    DispatchQueue.main.async {
                        self.copyStatusChanged = monitor.showCopyStateChangedPopUp
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
//                            self.copyStatusChanged = !status
//                        }
                    
                }
            }
        }
    }
    
    func initializeSelectList() {
        print("updating select list")
        self.selectList = clipboardGroups.map { clipboardGroup in
            let isExpanded = self.findExpandedState(for: clipboardGroup)
            return SelectedGroup(group: clipboardGroup, isExpanded: isExpanded)
        }
        print("COUNT: clipboardGroups: \(clipboardGroups.count) | selectList: \(self.selectList.count)\n")
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
                print("content view showing alert: \(self.showingAlert)\n")
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
                    if !isFocused || !isSelectingCategory {

                        if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
                            DispatchQueue.main.async {
                                self.showingAlert = true
                                activeAlert = .clear
                            }
                            return nil
                        }
                        else if event.modifierFlags.contains(.command) {
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
                case 35:
                    // Handle Command + Shift + P
                    if event.modifierFlags.contains(.command) {
                        if event.modifierFlags.contains(.shift) {
                            self.menuManager.toggleCopying()
                            
                            return nil // no more beeps
                        }
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
                        justScrolledToTop = true
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
//                    print("down")
                    
                    if event.modifierFlags.contains(.command) {
                        scrollToBottom = true
                        justScrolledToTop = false
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
                case 33:
                    // handle cmd + [
                    if !isFocused || !isSelectingCategory {
                        if event.modifierFlags.contains(.command) {
                            clipboardManager.expandAll(for: selectList)
                            return nil
                        }
                    }
                case 30:
                    // handle cmd + ]
                    if !isFocused || !isSelectingCategory {
                        if event.modifierFlags.contains(.command) {
                            clipboardManager.contractAll(for: selectList)
                            return nil
                        }
                    }
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
    
    let userDefaultsManager = UserDefaultsManager.shared
    
    var selectGroup: SelectedGroup
    @Binding var selectList: [SelectedGroup]
    
    @Binding var parentShowingAlert: Bool
    @Binding var groupShowingAlert: Bool
    @State private var showingDeleteAlert = false
    @State private var itemShowingDeleteAlert = false
    
    @Binding var isSearchFocused: Bool
    @Binding var isSelectingCategory: Bool
    
    @Binding var windowWidth: CGFloat
    
    @Binding var isGroupSelected: Bool
        
    @State private var imageSizeMultiple: CGFloat = 0.7
        
//    @State private var isGroupExpanded: Bool = false
    
    @State private var shouldSelectGroup: Bool = true
    
    @State private var shouldShowItemIcon: Bool = true
    
    
    var body: some View {
        let group = selectGroup.group
        if group.count == 1, let item = group.itemsArray.first {
            ClipboardItemView(item: item, selectGroup: selectGroup, selectList: $selectList, isPartOfGroup: false, imageSizeMultiple: $imageSizeMultiple, showingDeleteAlert: $itemShowingDeleteAlert, isSelected: Binding(
                get: { self.clipboardManager.selectedItem == item },
                set: { newItem in
                    isGroupSelected = true
                    self.clipboardManager.selectedGroup = selectGroup
                }))
            .id(item.objectID)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill((clipboardManager.selectedGroup == selectGroup && clipboardManager.selectedItem == nil) ? 
                      (isGroupSelected ? (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray) : (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray).opacity(0.5)) : (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray).opacity(0.5))
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
            .onChange(of: self.parentShowingAlert ||  self.showingDeleteAlert || self.itemShowingDeleteAlert) {
                if self.parentShowingAlert ||  self.showingDeleteAlert || self.itemShowingDeleteAlert {
                    self.groupShowingAlert = true
                }
                else {
                    self.groupShowingAlert = false
                }
            }
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
                                .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut, value: selectGroup.isExpanded)
                        .padding(.leading, 5)
                        
                        
                        // icon view for each item in group
                        let visibleItems = calculateVisibleItems(for: group.itemsArray, maxWidth: windowWidth - 87) // 87 is the pixel width of the buttons and stuff on the right
                        ScrollView(.horizontal, showsIndicators: false) {
                            ZStack(alignment: .trailing) {
                                HStack(spacing: -20) { // Negative spacing for overlapping
                                    ForEach(visibleItems, id: \.self) { item in
                                        itemIconView(item)
                                            .zIndex(Double(visibleItems.count - group.itemsArray.firstIndex(of: item)!)) // Ensure the first item is on top
                                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                                    }
                                }
                                
                                // lil icon showing there are more items than visible
                                if visibleItems.count < group.itemsArray.count {
                                    let count = group.itemsArray.count - visibleItems.count
                                    ZStack {
                                        
                                        Image(systemName: "circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 25, height: 25)
                                            .foregroundStyle(UserDefaultsManager.shared.darkMode ? .black : .white)
                                            .opacity(0.65)
                                        
                                        Image(systemName: "circle")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 25, height: 25)
                                            .foregroundStyle(UserDefaultsManager.shared.darkMode ? .white : .black)
                                        
                                        Text("+\(count)")
                                            .font(.system(size: 12))
                                            .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                                    }
                                    .padding(.top, 18)
                                    .padding(.trailing, 5)
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
                                .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Copy Item")
                        
                        Button(action: {
                            isGroupSelected = true
                            clipboardManager.selectedGroup = selectGroup
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
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
                        .fill((clipboardManager.selectedGroup == selectGroup && clipboardManager.selectedItem == nil) ? (isGroupSelected ? (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray) : (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray).opacity(0.5)) : (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray).opacity(0.5))
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
                                    ClipboardItemView(item: item, selectGroup: selectGroup, selectList: $selectList, isPartOfGroup: true, imageSizeMultiple: $imageSizeMultiple, showingDeleteAlert: $itemShowingDeleteAlert, isSelected: Binding(
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
            .onChange(of: self.parentShowingAlert ||  self.showingDeleteAlert || self.itemShowingDeleteAlert) {
                if self.parentShowingAlert ||  self.showingDeleteAlert || self.itemShowingDeleteAlert {
                    self.groupShowingAlert = true
                }
                else {
                    self.groupShowingAlert = false
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
    
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            
            if let currSelectGroup = clipboardManager.selectedGroup {
                
                if event.type == .keyDown && !self.parentShowingAlert &&  !self.showingDeleteAlert && !self.itemShowingDeleteAlert {
                    print("Group view showing alert: \(self.parentShowingAlert) or \(self.showingDeleteAlert) or \(self.itemShowingDeleteAlert)")
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
                            if event.modifierFlags.contains(.command) {
                                // this is where I would open the file/folder
                                if let selectedGroup = clipboardManager.selectedGroup {
                                    
                                    // single item group
                                    var itemToOpen: ClipboardItem?
                                    if selectedGroup.group.count == 1 && clipboardManager.selectedItem == nil, let item = selectedGroup.group.itemsArray.first {
                                        itemToOpen = item
                                    }
                                    // item in group
                                    else if let item = clipboardManager.selectedItem {
                                        itemToOpen = item
                                    }
                                    
                                    if let itemToOpen = itemToOpen {
                                        if let filePath = itemToOpen.filePath {
                                            if itemToOpen.type == "alias" {
                                                if let resolvedUrl = clipboardManager.clipboardMonitor?.resolveAlias(fileUrl: URL(fileURLWithPath: filePath)),
                                                   let resourceValues = try? resolvedUrl.resourceValues(forKeys: [.isDirectoryKey, .isAliasFileKey]) {
                                                    if resourceValues.isAliasFile == true || resourceValues.isDirectory == true {
                                                        clipboardManager.openFolder(filePath: resolvedUrl.path)
                                                        return nil
                                                    } else {
                                                        clipboardManager.openFile(filePath: resolvedUrl.path)
                                                        return nil
                                                    }
                                                }
                                            } else if let type = itemToOpen.type, type == "folder" || type == "removable" || type == "zipFile" || type == "dmgFile" || type == "randomFile" || type == "execFile" {
                                                clipboardManager.openFolder(filePath: filePath)
                                                return nil
                                            } else if itemToOpen.type == "file" || itemToOpen.type == "image" || itemToOpen.type == "app" || itemToOpen.type == "calendarApp" || itemToOpen.type == "settingsApp" || itemToOpen.type == "photoBoothApp" {
                                                clipboardManager.openFile(filePath: filePath)
                                                return nil
                                            }
                                        }
                                    }
                                }
                            }
                            else {
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
                    default:
                        break
                    }
                }
            }
            return event
        }
    }
    
    func calculateVisibleItems(for items: [ClipboardItem], maxWidth: CGFloat) -> [ClipboardItem] {
//        print("maxWidth: \(maxWidth)")
        var visibleItems: [ClipboardItem] = []
        var currentWidth: CGFloat = 42 + 20 // 42 is the pixel width of the stuff on the left, 20 is becuase one item doesnt have negative spacing
        
        for item in items {
            let iconWidth: CGFloat = getItemIconWidth(item: item)

            currentWidth += iconWidth - 20 // Account for negative spacing

            if currentWidth <= maxWidth {
                visibleItems.append(item)
            } else {
                break
            }
        }

        return visibleItems
    }
    
    func getItemIconWidth(item : ClipboardItem) -> CGFloat {
        switch item.type {
        case "text", "file", "zipFile", "dmgFile", "randomFile", "removable", "folder", "execFile":
            return CGFloat(60)
        case "app", "calendarApp", "photoBoothApp", "settingsApp":
            return CGFloat(70)
        case "image":
            return CGFloat(80)
        case "alias" :
            if item.imageData == nil {
                return CGFloat(80)
            }
            else {
                return CGFloat(60)
            }
        default:
            return CGFloat(60)
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
    
    @Binding var showingDeleteAlert: Bool
            
    @Binding var isSelected: Bool
                
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
                else if item.type == "image" || item.type == "app",
                                let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: (item.type == "app" ? 80 : 70) * imageSizeMultiple)
                        .cornerRadius(8)
                        .clipped()
                    
                    if let content = item.content {
                        if item.type == "app", let appName = content.split(separator: ".").first {
                            Text(appName)
                                .font(.subheadline)
                                .bold()
                                .lineLimit(1)
                        }
                        else {
                            Text(content)
                                .font(.subheadline)
                                .bold()
                                .lineLimit(1)
                        }
                    }
                }
                else if item.type == "calendarApp" || item.type == "settingsApp" || item.type == "photoBoothApp" {
                    switch item.type {
                    case "calendarApp":
                        Image("CalendarIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80 * imageSizeMultiple)
                    case "settingsApp":
                        Image("SystemSettingsIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80 * imageSizeMultiple)
                    case "photoBoothApp":
                        Image("PhotoBoothIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80 * imageSizeMultiple)
                    default:
                        Image("RandomFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 70 * imageSizeMultiple)
                    }
                    if let content = item.content, let content = content.split(separator: ".").first {
                        Text(content)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                }
                else if item.type == "file",
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
                else if item.type == "zipFile" || item.type == "dmgFile" || item.type == "randomFile" || item.type == "execFile" {
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
                    case "execFile":
                        Image("ExecFileThumbnail")
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
                                clipboardManager.openFolder(filePath: resolvedUrl.path)
                            }) {
//                                Image(systemName: "rectangle.portrait.and.arrow.right")
//                                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                                Image(systemName: "folder")
                                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 5)
                            .help("Open Folder")
                        } else {
                            Button(action: {
                                clipboardManager.openFile(filePath: resolvedUrl.path)
                            }) {
//                                Image(systemName: "rectangle.portrait.and.arrow.right")
//                                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                                Image(systemName: "folder")
                                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)

                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 5)
                            .help("Open File")
                        }
                    }
                } else if let type = item.type, type == "folder" || type == "removable" || type == "zipFile" || type == "dmgFile" || type == "randomFile" || type == "execFile" {
                    Button(action: {
                        clipboardManager.openFolder(filePath: filePath)
                    }) {
//                        Image(systemName: "rectangle.portrait.and.arrow.right")
//                            .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                        Image(systemName: "folder")
                            .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 5)
                    .help("Open \(type.contains("file") ? "File" : "Folder")")
                } else if item.type == "file" || item.type == "image" || item.type == "app" || item.type == "calendarApp" || item.type == "settingsApp" || item.type == "photoBoothApp" {
                    Button(action: {
                        clipboardManager.openFile(filePath: filePath)
                    }) {
//                        Image(systemName: "rectangle.portrait.and.arrow.right")
//                            .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                        Image(systemName: "folder")
                            .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 5)
                    .help("Open \(item.type == "image" ? "Image" : (item.type == "app" ? "App" : "File"))")
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
                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
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
                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
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
        .fill(isPartOfGroup ? (isSelected ? (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray) :                                 (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray).opacity(0.5)) : Color.clear)
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
}

struct GroupItemIconView: View {
    let item: ClipboardItem
    @Binding var currentWidthOfAllIcons: CGFloat
    @State private var shouldShowItemIcon: Bool = true
    
    var body: some View {
        if shouldShowItemIcon {
            itemIconView(item)
                .background(GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            let iconWidth = geo.frame(in: .local).width
                            let availableWidth = CGFloat(299)
                            currentWidthOfAllIcons += iconWidth
                            if currentWidthOfAllIcons > availableWidth {
                                shouldShowItemIcon = false
                            }
                        }
                })
        }
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
        else if item.type == "image" || item.type == "app",
                let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 80, maxHeight: (item.type == "app" ? 70 : 60), alignment: .center)
                    .cornerRadius(8)
                    .clipped()
                
        }
        else if item.type == "calendarApp" || item.type == "settingsApp" || item.type == "photoBoothApp" {
            switch item.type {
            case "calendarApp":
                Image("CalendarIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 70)
            case "settingsApp":
                Image("SystemSettingsIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 70)
            case "photoBoothApp":
                Image("PhotoBoothIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 70)
            default:
                Image("FolderThumbnail")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            }
        }
        else if item.type == "file",
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
        else if item.type == "zipFile" || item.type == "dmgFile" || item.type == "randomFile" || item.type == "execFile" {
            switch item.type {
            case "zipFile":
                Image("ZipFileThumbnail")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            case "dmgFile":
                Image("DmgFileThumbnail")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            case "randomFile":
                Image("RandomFileThumbnail")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            case "execFile":
                Image("ExecFileThumbnail")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            default:
                Image("RandomFileThumbnail")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
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
