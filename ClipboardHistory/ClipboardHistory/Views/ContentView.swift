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
    
    @ObservedObject var userDefaultsManager = UserDefaultsManager.shared
    @ObservedObject var viewStateManager = ViewStateManager.shared
    let menuManager = MenuManager.shared
    let windowManager = WindowManager.shared
        
    @State private var showAlert = false
    @State private var activeAlert: ActiveAlert = .clear

    @State private var atTopOfList = true
    
    @State private var isSelectingCategory: Bool = false
    @State private var selectedTypes: Set<UUID> = []
    
    @State private var imageSizeMultiple: CGFloat = 1
    
    @State private var openedFileFolderOrApp: Bool = false
    @State private var openedStateChanged: Bool = false
        
    @State private var copyStatusChanged: Bool = false    
    @State private var showCopyFailedFeedback: Bool = false
    
    @State private var isClearButtonHovered: Bool = false
    
    @State private var darkMode: Bool = true
    
    @State private var windowWidth: CGFloat = 0
    @State private var windowHeight: CGFloat = 0
    
    @State private var searchItemCount: Int = 0
    @State private var fetchedItemCount: Int = 0
    
    private var clipboardGroups: [ClipboardGroup] {
        return clipboardManager.search(fetchedClipboardGroups: fetchedClipboardGroups, searchText: self.viewStateManager.searchText, selectedTypes: selectedTypes)
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
                    self.viewStateManager.isSearchFocused = false
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
            
            if userDefaultsManager.hideDeleteAlerts && viewStateManager.deleteOccurred {
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
                    Text("Item Deleted!")
                        .font(.subheadline)
                        .bold()
                        
                        .cornerRadius(8)
                        .frame(alignment: .center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: viewStateManager.deleteOccurred)
                // x: frame_width/2  |  y: -(window_height/2 - frame_height)
                .position(x: 90/2, y: -(self.windowHeight/2 - 24))
                .frame(width: 90, height: 24)
                .zIndex(5)
            
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            if self.openedStateChanged {
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
                    Text("Opening!")
                        .font(.subheadline)
                        .bold()
                        
                        .cornerRadius(8)
                        .frame(alignment: .center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: self.openedStateChanged)
                // x: frame_width/2  |  y: -(window_height/2 - frame_height)
                .position(x: 100/2, y: -(self.windowHeight/2 - 24))
                .frame(width: 100, height: 24)
                .zIndex(5)
            
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(darkMode ? .white : .black)
                        .padding(.leading, 8)
                        .onTapGesture {
                            self.viewStateManager.isSearchFocused = false
//                            self.isFocused = false
                        }
                    
                    SearchBarView(showAlert: $showAlert, isSelectingCategory: $isSelectingCategory, searchItemCount: $searchItemCount, fetchedItemCount: $fetchedItemCount)
//                        .focused($isFocused)
                        .padding(.trailing, (fetchedClipboardGroups.count <= 0) ? 10 : 0)
                        .onAppear() {
                            fetchedItemCount = fetchedClipboardGroups.count
                            searchItemCount = viewStateManager.selectList.count
                        }
                        .onChange(of: fetchedClipboardGroups.count) {
                            fetchedItemCount = fetchedClipboardGroups.count
                        }
                        .onChange(of: viewStateManager.selectList.count) {
                            searchItemCount = viewStateManager.selectList.count
                        }
                    
                    if fetchedClipboardGroups.count > 0 {
                        Button(action: {
                            self.isSelectingCategory.toggle()
                            self.viewStateManager.isSearchFocused = false
                        }) {
                            Image(systemName: "line.horizontal.3.decrease.circle")
                                .foregroundColor(darkMode ? .white : .black)
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
                            if !self.atTopOfList && !self.viewStateManager.justScrolledToTop {
                                self.viewStateManager.scrollToTop = true
                                self.viewStateManager.justScrolledToTop = true
                                
                                self.viewStateManager.isSearchFocused = false
//                                self.isFocused = false
                            }
                            else if self.atTopOfList || self.viewStateManager.justScrolledToTop {
                                self.viewStateManager.scrollToBottom = true
                                self.viewStateManager.justScrolledToTop = false
                                
                                self.viewStateManager.isSearchFocused = false
//                                self.isFocused = false
                            }
                        }) {
                            Image(systemName: (!self.atTopOfList && !self.viewStateManager.justScrolledToTop) ? "arrow.up.circle" : "arrow.down.circle")
                                .foregroundColor(darkMode ? .white : .black)
                                .padding(.trailing, 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(!self.atTopOfList && !self.viewStateManager.justScrolledToTop ? "Scroll to Top" : "Scroll to Bottom")
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
                            ForEach(viewStateManager.selectList.indices, id: \.self) { index in
                                if index >= 0 && index < viewStateManager.selectList.count {
                                    ClipboardGroupView(selectGroup: viewStateManager.selectList[index], showAlert: $showAlert, activeAlert: $activeAlert, isSelectingCategory: $isSelectingCategory, windowWidth: $windowWidth, openedFileFolderOrApp: $openedFileFolderOrApp,
                                                       isGroupSelected: Binding(
                                                        get: { if index >= 0 && index < viewStateManager.selectList.count { return self.clipboardManager.selectedGroup == viewStateManager.selectList[index] }
                                                            else { return false } },
                                                        set: { isSelected in
                                                            if index >= 0 && index < viewStateManager.selectList.count{
                                                                self.clipboardManager.selectedGroup = isSelected ? viewStateManager.selectList[index] : nil
                                                            }
//                                                            isFocused = false
                                                            self.viewStateManager.isSearchFocused = false
                                                        }))
                                    .id(viewStateManager.selectList[index].group.objectID)
                                    .animation((atTopOfList || userDefaultsManager.noDuplicates) ? .default : nil, value: viewStateManager.selectList.first?.group.objectID)
                                }
                            }
                            
                        } //scrolls when using the arrow keys
                        .onChange(of: clipboardManager.selectedGroup, initial: false) {
                            if let selectedGroup = clipboardManager.selectedGroup, let index = viewStateManager.selectList.firstIndex(of: selectedGroup) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollView.scrollTo(viewStateManager.selectList[index].group.objectID)
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
                                if let selectedGroup = clipboardManager.selectedGroup, let index = viewStateManager.selectList.firstIndex(of: selectedGroup) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            scrollView.scrollTo(viewStateManager.selectList[index].group.objectID, anchor: (selectedGroup.isExpanded && clipboardManager.selectedItem == nil) ? .top : nil)
                                        }
//                                    }
                                }
                            }
                        }
                        
                        .onChange(of: self.viewStateManager.scrollToTop, initial: false) {
                            if viewStateManager.selectList.count > 0 {
                                withAnimation() {
                                    scrollView.scrollTo(viewStateManager.selectList.first?.group.objectID, anchor: .top)
                                    self.viewStateManager.scrollToTop = false
                                    self.viewStateManager.justScrolledToTop = true
                                    clipboardManager.selectedGroup = viewStateManager.selectList.first
                                }
                            }
                        }
                        .onChange(of: self.viewStateManager.scrollToBottom, initial: false) {
                            if viewStateManager.selectList.count > 0 {
                                withAnimation() {
                                    scrollView.scrollTo(viewStateManager.selectList.last?.group.objectID)
                                    self.viewStateManager.scrollToBottom = false
                                    self.viewStateManager.justScrolledToTop = false
                                    clipboardManager.selectedGroup = viewStateManager.selectList.last
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
                    showAlert = true
                    activeAlert = .clear
                } label: {
                    Text("Clear All")
                        .frame(maxWidth: 90)
                }
                .help("Clear All Items")
                .buttonStyle(.bordered)
                .tint(Color(.darkGray))
                .scaleEffect(isClearButtonHovered ? 1.035 : 1.0)
                .shadow(color: isClearButtonHovered ? Color(.darkGray) : .clear, radius: isClearButtonHovered ? 2 : 0)
                .onHover { isClearButtonHovered in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isClearButtonHovered = isClearButtonHovered
                    }
                }
                .padding(.bottom, 8)
                .alert(isPresented: $showAlert) {
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
                                    clipboardManager.deleteGroup(group: clipboardManager.selectedGroup?.group, selectList: viewStateManager.selectList, viewContext: viewContext)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .onAppear {
                    clipboardManager.selectedGroup = viewStateManager.selectList.first
                }

            }
            .onAppear {
                clipboardManager.selectedGroup = viewStateManager.selectList.first
                darkMode = userDefaultsManager.darkMode
                setUpKeyboardHandling()
                initializeSelectList()
            }
            .onChange(of: clipboardGroups.count) { oldValue, newValue in
                if clipboardGroups.count == 1 {
                    clipboardManager.selectedGroup = viewStateManager.selectList.first
                }
                initializeSelectList()
            }
            .onChange(of: clipboardGroups.first) { oldValue, newValue in
                // when last item gets deleted and so the count doesnt change
                if clipboardGroups.count == 1 {
                    clipboardManager.selectedGroup = viewStateManager.selectList.first
                }
                initializeSelectList()
            }
            .onChange(of: viewStateManager.selectList.first) { oldValue, newValue in
                // is user wants no dupes, then select the top when a new copy comes in
                if userDefaultsManager.noDuplicates {
                    clipboardManager.selectedGroup = viewStateManager.selectList.first
                }
            }
            .onChange(of: userDefaultsManager.darkMode) {
                darkMode = userDefaultsManager.darkMode
            }
            .onChange(of: openedFileFolderOrApp) {
                DispatchQueue.main.async {
                    self.openedStateChanged = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.openedStateChanged = false
                        openedFileFolderOrApp = false
                    }
                }
            }
            // triggered when settings changed
            .onChange(of: userDefaultsManager.pauseCopying) {
                DispatchQueue.main.async {
                    self.copyStatusChanged = true
                    self.windowManager.showCopyPausedPopover(copyingFailed: nil, copyingPaused: userDefaultsManager.pauseCopying)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        self.copyStatusChanged = false
                    }
                }
            }
            .onReceive(clipboardManager.clipboardMonitor?.copyFailedStateChange ?? PassthroughSubject<Void, Never>()) { _ in
                // needed because this change wont update unless app is active
                if let monitor = clipboardManager.clipboardMonitor {
                    self.showCopyFailedFeedback = monitor.showCopyFailedFeedback
                }
                self.windowManager.showCopyPausedPopover(copyingFailed: true, copyingPaused: nil)
            }
            .onReceive(clipboardManager.clipboardMonitor?.copyStatusStateChange ?? PassthroughSubject<Void, Never>()) { _ in
                // needed because this change wont update unless app is active
                if let monitor = clipboardManager.clipboardMonitor {
                    self.copyStatusChanged = monitor.showCopyStateChangedPopUp                    
                }
                self.windowManager.showCopyPausedPopover(copyingFailed: nil, copyingPaused: clipboardManager.clipboardMonitor?.isCopyingPaused)
            }
        }
    }
    
    func initializeSelectList() {
        self.viewStateManager.selectList = clipboardGroups.map { clipboardGroup in
            let isExpanded = self.findExpandedState(for: clipboardGroup)
            return SelectedGroup(group: clipboardGroup, isExpanded: isExpanded)
        }
    }
    
    func findExpandedState(for inputGroup: ClipboardGroup) -> Bool {
        // if this group was already in selectList, return its isExpanded
        return viewStateManager.selectList.first(where: { $0.group == inputGroup })?.isExpanded ?? false
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
                currentIndex = viewStateManager.selectList.firstIndex(of: group)
//                print("\(currentIndex)\n")
            }
            if currentIndex == nil {
                if !viewStateManager.selectList.isEmpty {
                    clipboardManager.selectedGroup = viewStateManager.selectList[0]
                    if let group = clipboardManager.selectedGroup?.group, group.count == 1 {
                    clipboardManager.selectedGroup?.selectedItem = clipboardManager.selectedGroup?.group.itemsArray.first
                    }
                    currentIndex = 0
                }
                else {
                    return event
                }
            }
            if event.type == .keyDown && !self.showAlert {
                switch event.keyCode {
                case 13:
                    if event.modifierFlags.contains(.command) {
                    // handle Cmd + W
                        if let window = WindowManager.shared.window, window.isKeyWindow {
                            WindowManager.shared.hideWindow()
                        }
                        else if let popoverWindow = WindowManager.shared.popover?.contentViewController?.view.window, popoverWindow.isKeyWindow {
                           // WindowManager.shared.hidePopOutWindow()
                            WindowManager.shared.hideWindow()
                            SettingsWindowManager.shared.closeSettingsWindow()
                        }
                        return nil
                    }
                case 8:
                    if event.modifierFlags.contains(.command) {
                        if !self.viewStateManager.isSearchFocused || !isSelectingCategory {
                            // Handle Command + C
                            if clipboardManager.selectedItem != nil {
                                clipboardManager.copySelectedItemInGroup()
                            }
                            else {
                                clipboardManager.copySelectedGroup()
                            }
                        }
                        return nil
                    }
                case 51:
                    // Handle Command + Del
                    if !self.viewStateManager.isSearchFocused || !isSelectingCategory {

                        if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
                            DispatchQueue.main.async {
                                self.showAlert = true
                                activeAlert = .clear
                            }
                            return nil
                        }
                        else if event.modifierFlags.contains(.command) {
                            DispatchQueue.main.async {
                                if userDefaultsManager.hideDeleteAlerts {
                                    if let item = clipboardManager.selectedItem {
                                        clipboardManager.deleteItem(item: item, viewContext: viewContext, shouldSave: true)
                                    }
                                    else {
                                        clipboardManager.deleteGroup(group: clipboardManager.selectedGroup?.group, selectList: viewStateManager.selectList, viewContext: viewContext)
                                    }
                                    viewStateManager.deleted()
                                }
                                else {
                                    self.showAlert = true
                                    activeAlert = .delete
                                }
                            }
                            return nil
                        }
                    }
                case 3:
                    if event.modifierFlags.contains(.command) {
                        // Handle Command + F
                        
                        isSelectingCategory = false
                        self.viewStateManager.isSearchFocused = true
                       
                        return nil // no more beeps
                    }
                case 35:
                    // Handle Command + Shift + P
                    if event.modifierFlags.contains(.command) {
                        if event.modifierFlags.contains(.shift) {
                            self.menuManager.toggleCopying(shouldDelay: true)
                            
                            return nil // no more beeps
                        }
                    }
                case 126:
                    // Handle up arrow
                    self.viewStateManager.isSearchFocused = false
                    isSelectingCategory = false
                    
                    if event.modifierFlags.contains(.command) {
                        self.viewStateManager.scrollToTop = true
                        self.viewStateManager.justScrolledToTop = true
                    }
                    else {
                        if let currIndex = currentIndex, currIndex - 1 >= 0 {
                            let aboveGroup = viewStateManager.selectList[currIndex - 1]
                            let currGroup = viewStateManager.selectList[currIndex]
                            
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
                            let currGroup = viewStateManager.selectList[currIndex]
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
                    self.viewStateManager.isSearchFocused = false
                    self.isSelectingCategory = false
                    
                    if event.modifierFlags.contains(.command) {
                        self.viewStateManager.scrollToBottom = true
                        self.viewStateManager.justScrolledToTop = false
                    }
                    else {
                        if let currIndex = currentIndex, currIndex < viewStateManager.selectList.count - 1 {
                            let currGroup = viewStateManager.selectList[currIndex]
                            if currGroup.isExpanded {
                                if let selectedItem = clipboardManager.selectedItem {
                                    if let currItemIndex = currGroup.group.itemsArray.firstIndex(where: { $0 == selectedItem }),
                                       currItemIndex + 1 < currGroup.group.itemsArray.count {
                                        clipboardManager.selectedItem = currGroup.group.itemsArray[currItemIndex + 1]
                                    } else {
                                        if currIndex + 1 < viewStateManager.selectList.count {
                                            clipboardManager.selectedGroup = viewStateManager.selectList[currIndex + 1]
                                            clipboardManager.selectedItem = nil
                                        }
                                    }
                                } else {
                                    clipboardManager.selectedItem = currGroup.group.itemsArray.first
                                }
                            }
                            else {
                                if currIndex + 1 < viewStateManager.selectList.count {
                                    clipboardManager.selectedGroup = viewStateManager.selectList[currIndex + 1]
                                    clipboardManager.selectedItem = nil
                                }
                            }
                        }
                        else if let currIndex = currentIndex {
                            // at bottom of selectList, but group is expanded
                            let currGroup = viewStateManager.selectList[currIndex]
                            if currGroup.isExpanded {
                                if let selectedItem = clipboardManager.selectedItem {
                                    if let currItemIndex = currGroup.group.itemsArray.firstIndex(where: { $0 == selectedItem }),
                                       currItemIndex + 1 < currGroup.group.itemsArray.count {
                                        clipboardManager.selectedItem = currGroup.group.itemsArray[currItemIndex + 1]
                                    }
                                    else {
                                        if currIndex + 1 < viewStateManager.selectList.count {
                                            clipboardManager.selectedGroup = viewStateManager.selectList[currIndex + 1]
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
                    
                    self.viewStateManager.isSearchFocused = false
                    isSelectingCategory = false
                    
                    if clipboardManager.selectedGroup?.isExpanded == true {
                        if clipboardManager.selectedItem != nil {
                            clipboardManager.selectedItem = nil
                        }
                        else if let selectedGroup = clipboardManager.selectedGroup {
                            clipboardManager.contract(for: selectedGroup)
                        }
                    }
                    return nil
                case 115, 116:
                    // Handle Home or Page Up Key action
                    self.viewStateManager.scrollToTop = true
                    return nil
                case 119, 121:
                    // Handle End or Page Down Key action
                    self.viewStateManager.scrollToBottom = true
                    return nil
                case 33:
                    // handle cmd + [
                    if !self.viewStateManager.isSearchFocused || !isSelectingCategory {
                        if event.modifierFlags.contains(.command) {
                            clipboardManager.expandAll(for: self.viewStateManager.selectList)
                            return nil
                        }
                    }
                case 30:
                    // handle cmd + ]
                    if !self.viewStateManager.isSearchFocused || !isSelectingCategory {
                        if event.modifierFlags.contains(.command) {
                            clipboardManager.contractAll(for: self.viewStateManager.selectList)
                            return nil
                        }
                    }
                default:
                    return event
                }
            }
            return event
        }
    }
    
}

struct ClipboardGroupView: View {

    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @ObservedObject var viewStateManager = ViewStateManager.shared

    let userDefaultsManager = UserDefaultsManager.shared
    let windowManager = WindowManager.shared
    let settingsWindowManager = SettingsWindowManager.shared
    
    var selectGroup: SelectedGroup
    
    @Binding var showAlert: Bool
    @Binding var activeAlert: ActiveAlert
    
    @Binding var isSelectingCategory: Bool
    
    @Binding var windowWidth: CGFloat
    
    @Binding var openedFileFolderOrApp: Bool
    
    @Binding var isGroupSelected: Bool
        
    @State private var imageSizeMultiple: CGFloat = 0.7
            
    @State private var shouldSelectGroup: Bool = true
    
    @State private var shouldShowItemIcon: Bool = true
    
    @State private var isGroupHovered = false
    @State private var isItemHovered = false
    
    var body: some View {
        let group = selectGroup.group
        if group.count == 1, let item = group.itemsArray.first {
            ClipboardItemView(item: item, selectGroup: selectGroup, isPartOfGroup: false, imageSizeMultiple: 1.0, showAlert: $showAlert, activeAlert: $activeAlert, openedFileFolderOrApp: $openedFileFolderOrApp, isSelected: Binding(
                get: {
                    self.clipboardManager.selectedGroup == selectGroup
                },
                set: { newItem in
                    isGroupSelected = true
                    self.clipboardManager.selectedGroup = selectGroup
                    self.clipboardManager.selectedItem = nil
                }))
            .id(item.objectID)
            
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
                            if userDefaultsManager.hideDeleteAlerts {
                                if let item = clipboardManager.selectedItem {
                                    clipboardManager.deleteItem(item: item, viewContext: viewContext, shouldSave: true)
                                }
                                else {
                                    clipboardManager.deleteGroup(group: clipboardManager.selectedGroup?.group, selectList: viewStateManager.selectList, viewContext: viewContext)
                                }
                                viewStateManager.deleted()
                            }
                            else {
                                self.showAlert = true
                                activeAlert = .delete
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                        }
                        .help("Delete Item")
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.leading, 5)
                        .padding(.trailing, 10)
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
                    .scaleEffect(isGroupHovered ? 1.02 : 1.0)
                    .shadow(color: isGroupHovered ? (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color(.gray)) : .clear, radius: isGroupHovered ? 2 : 0)
                    .onHover { isGroupHovered in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.isGroupHovered = isGroupHovered
                        }
                    }
                    
                    .contentShape(Rectangle()) // Makes the entire area tappable
                    .onTapGesture(count: 2) { // double tap detected immediately
                        isGroupSelected = true
                        clipboardManager.selectedGroup = selectGroup
                        clipboardManager.selectedItem = nil
                        clipboardManager.copySelectedGroup()
                    }
                    .simultaneousGesture( // execute single-tap immediately
                        TapGesture(count: 1).onEnded {
                            // Single tap action
                            isGroupSelected = true
                            clipboardManager.selectedGroup = selectGroup
                            clipboardManager.selectedItem = nil
                        }
                    )
                    .onChange(of: clipboardManager.selectedGroup?.isExpanded) {
                        if clipboardManager.selectedGroup?.isExpanded == false {
                            clipboardManager.selectedItem = nil
                        }
                    }
                    
                    if selectGroup.isExpanded {
                        ScrollViewReader { scrollView in
                            LazyVStack(spacing: 0) {
                                ForEach(group.itemsArray, id: \.self) { item in
                                    ClipboardItemView(item: item, selectGroup: selectGroup, isPartOfGroup: true, imageSizeMultiple: 0.8, showAlert: $showAlert, activeAlert: $activeAlert, openedFileFolderOrApp: $openedFileFolderOrApp, isSelected: Binding(
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
        }
    }
    
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            
            if let currSelectGroup = self.clipboardManager.selectedGroup {
                
                if event.type == .keyDown && !self.showAlert {
                    switch event.keyCode {
                    case 124:
                        // right arrow to expand group
                        self.viewStateManager.isSearchFocused = false
                        self.isSelectingCategory = false
                        if !self.viewStateManager.isSearchFocused || !self.isSelectingCategory {
                            if currSelectGroup.group.count > 1 {
                                self.clipboardManager.expand(for: currSelectGroup)
                            }
                        }
                        return nil
                    case 123:
                        // left arrow to contract group
                        self.viewStateManager.isSearchFocused = false
                        self.isSelectingCategory = false
                        
                        // works like apple folder list view now
                        if !self.viewStateManager.isSearchFocused || !self.isSelectingCategory {
                            if currSelectGroup.group.count > 1 {
                                if self.clipboardManager.selectedGroup?.self.isExpanded == true {
                                    if self.clipboardManager.selectedItem != nil {
                                        self.clipboardManager.selectedItem = nil
                                    }
                                    else if let selectedGroup = self.clipboardManager.selectedGroup {
                                        self.clipboardManager.contract(for: selectedGroup)
                                    }
                                }
                            }
                        }
                        return nil
                    case 36, 76:
                        // Handle Enter or Return
                        if !self.viewStateManager.isSearchFocused || !self.isSelectingCategory {
                            if event.modifierFlags.contains(.command) {
                                // this is where I would open the file/folder
                                if let selectedGroup = self.clipboardManager.selectedGroup {
                                    
                                    // single item group
                                    var itemToOpen: ClipboardItem?
                                    if selectedGroup.group.count == 1 && self.clipboardManager.selectedItem == nil, let item = selectedGroup.group.itemsArray.first {
                                        itemToOpen = item
                                    }
                                    // item in group
                                    else if let item = self.clipboardManager.selectedItem {
                                        itemToOpen = item
                                    }
                                    
                                    if let itemToOpen = itemToOpen {
                                        if let filePath = itemToOpen.filePath {
                                            if itemToOpen.type == "alias" {
                                                if let resolvedUrl = self.clipboardManager.clipboardMonitor?.resolveAlias(fileUrl: URL(fileURLWithPath: filePath)),
                                                   let resourceValues = try? resolvedUrl.resourceValues(forKeys: [.isDirectoryKey, .isAliasFileKey]) {
                                                    if resourceValues.isAliasFile == true || resourceValues.isDirectory == true {
                                                        self.clipboardManager.openFolder(filePath: resolvedUrl.path)
                                                        self.openedFileFolderOrApp = true
                                                    } else {
                                                        self.clipboardManager.openFile(filePath: resolvedUrl.path)
                                                        self.openedFileFolderOrApp = true
                                                    }
                                                }
                                            } else if let type = itemToOpen.type, type == "folder" || type == "removable" || type == "zipFile" || type == "dmgFile" || type == "randomFile" || type == "execFile" {
                                                self.clipboardManager.openFolder(filePath: filePath)
                                                self.openedFileFolderOrApp = true
                                            } else if itemToOpen.type == "file" || itemToOpen.type == "image" || itemToOpen.type == "app" || itemToOpen.type == "calendarApp" || itemToOpen.type == "settingsApp" || itemToOpen.type == "photoBoothApp" {
                                                self.clipboardManager.openFile(filePath: filePath)
                                                self.openedFileFolderOrApp = true
                                            }
                                        }
                                    }
                                }
                            }
                            else {
                                if self.clipboardManager.selectedItem != nil {
                                    self.clipboardManager.copySelectedItemInGroup()
                                }
                                else {
                                    self.clipboardManager.copySelectedGroup()
                                }
                                
                                if userDefaultsManager.enterKeyHidesAfterCopy && !(settingsWindowManager.settingsWindow?.isKeyWindow ?? false)   {
                                    self.windowManager.hideApp()
                                }
                            }
                        }
                        return nil
                    default:
                        return event
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
    
    @ObservedObject var viewStateManager = ViewStateManager.shared
    @ObservedObject var userDefaultsManager = UserDefaultsManager.shared
    
    var item: ClipboardItem
    
    var selectGroup: SelectedGroup
        
    var isPartOfGroup: Bool
    
    var imageSizeMultiple: CGFloat
    
    @Binding var showAlert: Bool
    @Binding var activeAlert: ActiveAlert
            
    @Binding var openedFileFolderOrApp: Bool
    
    @Binding var isSelected: Bool
    
    @State private var isItemHovered: Bool = false
                
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
                        .frame(maxHeight: (item.type == "app" ? 70 : 60) * imageSizeMultiple)
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
                            .frame(idealWidth: 45,  maxHeight: 60 * imageSizeMultiple)
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
                        .frame(idealWidth: 60,  maxHeight: 60 * imageSizeMultiple)
                        .cornerRadius(8)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(Color(.black), lineWidth: 1)
//                        )
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
                            .frame(idealWidth: 45,  maxHeight: 60 * imageSizeMultiple)
                    case "dmgFile":
                        Image("DmgFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(idealWidth: 45,  maxHeight: 60 * imageSizeMultiple)
                    case "randomFile":
                        Image("RandomFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(idealWidth: 45,  maxHeight: 60 * imageSizeMultiple)
                    case "execFile":
                        Image("ExecFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(idealWidth: 45,  maxHeight: 60 * imageSizeMultiple)
                    default:
                        Image("RandomFileThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(idealWidth: 45,  maxHeight: 60 * imageSizeMultiple)
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
                            .frame(height: 55 * imageSizeMultiple)
                        Text("Macintosh HD")
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)
                    }
                    else {
                        Image("FolderThumbnail")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 55 * imageSizeMultiple)
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
                            .frame(height: 55 * imageSizeMultiple)
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
                                .frame(height: 55 * imageSizeMultiple)
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
                        .frame(height: 60 * imageSizeMultiple)
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
                                self.openedFileFolderOrApp = true
                            }) {
                                Image(systemName: "folder")
                                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 5)
                            .help("Open Folder")
                        } else {
                            Button(action: {
                                clipboardManager.openFile(filePath: resolvedUrl.path)
                                self.openedFileFolderOrApp = true
                            }) {
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
                        self.openedFileFolderOrApp = true
                    }) {
                        Image(systemName: "folder")
                            .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 5)
                    .help("Open \(type.contains("file") ? "File" : "Folder")")
                } else if item.type == "file" || item.type == "image" || item.type == "app" || item.type == "calendarApp" || item.type == "settingsApp" || item.type == "photoBoothApp" {
                    Button(action: {
                        clipboardManager.openFile(filePath: filePath)
                        self.openedFileFolderOrApp = true
                    }) {
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
                
                if userDefaultsManager.hideDeleteAlerts {
                    if let item = clipboardManager.selectedItem {
                        clipboardManager.deleteItem(item: item, viewContext: viewContext, shouldSave: true)
                    }
                    else {
                        clipboardManager.deleteGroup(group: clipboardManager.selectedGroup?.group, selectList: viewStateManager.selectList, viewContext: viewContext)
                    }
                    viewStateManager.deleted()
                }
                else {
                    self.showAlert = true
                    activeAlert = .delete
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
            }
            .help("Delete Item")
            .buttonStyle(BorderlessButtonStyle())
            .padding(.leading, 5)
            .padding(.trailing, 10)
        }
        .padding(.top, 3)
        .padding(.leading, 15)
        .padding(.trailing, 15)
        .padding(.bottom, 4)
        
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray) : (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color.gray).opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        )
        .scaleEffect(isItemHovered ? 1.02 : 1.0)
        .shadow(color: isItemHovered ? (UserDefaultsManager.shared.darkMode ? Color(.darkGray) : Color(.gray)) : .clear, radius: isItemHovered ? 2 : 0)
        .onHover { isItemHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isItemHovered = isItemHovered
            }
        }
        .contentShape(Rectangle()) // Makes the entire area tappable
        .onTapGesture(count: 2) { // double tap detected immediately
            isSelected = true
            clipboardManager.selectedGroup = selectGroup
            if isPartOfGroup {
                clipboardManager.selectedItem = item
                clipboardManager.copySelectedItemInGroup()
            }
            else {
                clipboardManager.selectedItem = nil
                clipboardManager.copySingleGroup()
            }
        }
        .simultaneousGesture( // execute single-tap immediately
            TapGesture(count: 1).onEnded {
                // Single tap action
                isSelected = true
                clipboardManager.selectedGroup = selectGroup
                if isPartOfGroup {
                    clipboardManager.selectedItem = item
                } else {
                    clipboardManager.selectedItem = nil
                }
            }
        )
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
