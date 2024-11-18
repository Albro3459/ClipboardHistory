//
//  SearchBarView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/21/24.
//

import SwiftUI
import AppKit
import Foundation

struct SearchBarView: View {
    @ObservedObject var userDefaultsManager = UserDefaultsManager.shared
    @ObservedObject var viewStateManager = ViewStateManager.shared
    let windowManager = WindowManager.shared
    
    
    @Binding var showAlert: Bool
    @Binding var isSelectingCategory: Bool
    @Binding var searchItemCount: Int
    @Binding var fetchedItemCount: Int
    
    @State var currSearchText: String = ""
    
    @State private var forceStateUpdate: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {

                ClearTextField(placeholder: "Search", text: $currSearchText)
                    .focused($isTextFieldFocused)
                    .padding(.top, 2)
                    .padding(.bottom, 4)
                    .padding(.trailing, currSearchText.isEmpty ? 21 : 0)
                    .help("Search Bar")
                    .onChange(of: self.viewStateManager.isSearchFocused) {
                        self.isTextFieldFocused = self.viewStateManager.isSearchFocused
                    }
                    .onChange(of: self.isTextFieldFocused) {
                        if isTextFieldFocused {
                            self.viewStateManager.isSearchFocused = true
                        }
                    }
                    .onChange(of: self.currSearchText) {
                        self.viewStateManager.searchText = self.currSearchText
                    }
                    

                if !self.currSearchText.isEmpty {
                    Button(action: {
                        self.currSearchText = ""
                        self.viewStateManager.searchText = ""
                        self.viewStateManager.isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .padding(.trailing, -2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Clear Search Text")
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                self.viewStateManager.isSearchFocused = false
                self.isTextFieldFocused = self.viewStateManager.isSearchFocused
                
                self.viewStateManager.searchText = ""
                self.currSearchText = self.viewStateManager.searchText
            }
            setUpKeyboardHandling()
        }
    }
    
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            
            if event.type == .keyDown && !self.showAlert {
                switch event.keyCode {
                case 53:
                    // Escape key
                    DispatchQueue.main.async {
                        if self.isSelectingCategory == true {
                            self.isSelectingCategory = false
                            self.viewStateManager.isSearchFocused = false
                            self.isTextFieldFocused = self.viewStateManager.isSearchFocused
                        }
                        else if self.viewStateManager.searchText != "" || 
                                    self.currSearchText != "" {
                            self.viewStateManager.searchText = ""
                            self.currSearchText = self.viewStateManager.searchText
                            self.forceStateUpdate.toggle()
                        }
                        else if self.isTextFieldFocused == true {
                            self.isSelectingCategory = false
                            self.viewStateManager.isSearchFocused = false
                            self.isTextFieldFocused = self.viewStateManager.isSearchFocused
                        }
                        else {
                            self.windowManager.hideApp()
                        }
                    }
                    return nil
                default:
                    return event
                }
            }
            return event
        }
    }
}

struct ClearTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = CustomTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.placeholderString = placeholder
        textField.isEditable = true
        textField.isSelectable = true
        
        textField.delegate = context.coordinator
        
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.focusRingType = .none

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ClearTextField

        init(_ parent: ClearTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            if let textField = notification.object as? NSTextField {
                self.parent.text = textField.stringValue
            }
        }
    }
}

class CustomTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "a": // Command + A (Select All)
                self.currentEditor()?.selectAll(nil)
                return true
            case "v": // Command + V (Paste)
                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                    self.currentEditor()?.insertText(clipboardText)
                    return true
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

struct ClipboardType: Identifiable {
    let id: UUID
    let name: String
    
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
    
    static func getTypeName(by id: UUID) -> String {
        switch id {
        case ClipboardType.text.id:
//            return "text"
            return ClipboardType.text.name
        case ClipboardType.image.id:
//            return "image"
            return ClipboardType.image.name
        case ClipboardType.fileFolder.id:
//            return "fileFolder"
            return ClipboardType.fileFolder.name
        case ClipboardType.group.id:
//            return "group"
            return ClipboardType.group.name
        case ClipboardType.selectAll.id:
//            return "selectAll"
            return ClipboardType.selectAll.name
        default:
            return ""
        }
    }
    
    static let text = ClipboardType(id: UUID(), name: "Text")
    static let image = ClipboardType(id: UUID(), name: "Images")
    static let fileFolder = ClipboardType(id: UUID(), name: "Files / Folders")
    static let group = ClipboardType(id: UUID(), name: "Groups")
    static let selectAll = ClipboardType(id: UUID(), name: "Select All")
}

struct TypeDropDownMenu: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @Binding var multiSelection: Set<UUID>
    @State private var isSelectAll: Bool = false
    @State private var deselectingFromAll: Bool = false
        
    var body: some View {
        VStack(alignment: .center) {
            ZStack {
                Rectangle()
                    .fill(.background)
                    .frame(height: 26)
                Text("Filter by type: ")
                    .fontWeight(.bold)
                    .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity)
            
            
            List(clipboardManager.types, id: \.id, selection: $multiSelection) { type in
                HStack {
                    Spacer()  // Pushes the text to the center
                    Text(type.name)
                        .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                        .fontWeight(type.name == "Select All" ? .bold : .medium)
                    Spacer()  // Ensures the text stays centered
                }
                .foregroundColor(UserDefaultsManager.shared.darkMode ? .white : .black)
                .listRowBackground(Color.gray.opacity(0.25))
                .listRowSeparator(.hidden)
                .onTapGesture(count: 1) {
                    // way overdone because of dragging, I cant turn of drag to select multiple list items unfortunately
                    if type.name == "Select All" || type.id == ClipboardType.selectAll.id {
                        if multiSelection.count == 0 {
                            if isSelectAll {
                                insertAll()
                            }
                            else {
                                isSelectAll = true
                            }
                        }
                        else if multiSelection.count == clipboardManager.types.count {
                            if !isSelectAll {
                                multiSelection.removeAll()
                            }
                            else {
                                isSelectAll = false
                            }
                        }
                        else {
                            isSelectAll.toggle()
                        }
                    }
                    else {
                        if multiSelection.contains(type.id) {
                            if multiSelection.count == clipboardManager.types.count {
                                deselectingFromAll = true
                                isSelectAll = false
                                
                                removeAllButMe(id: type.id)
                            }
                            else {
                                multiSelection.remove(type.id)
                                deselectingFromAll = true
                                isSelectAll = false
                            }
                        } else {
                            multiSelection.insert(type.id)
                        }
                    }
                }
                .scrollDisabled(true)
            }
            .scrollDisabled(true)
            .padding(.top, -11)
            .onChange(of: isSelectAll) {
                if isSelectAll {
                    insertAll()
                }
                else if isSelectAll == false && deselectingFromAll == false {
                    multiSelection.removeAll()
                }
                else if isSelectAll == false {
                    deselectingFromAll = false
                }
            }
            .onChange(of: multiSelection.count) {
                if multiSelection.count == clipboardManager.types.count-1 && !multiSelection.contains(ClipboardType.selectAll.id) {
                    isSelectAll = true
                }
            }
        }
    }
    private func insertAll() {
        multiSelection.insert(ClipboardType.selectAll.id)
        multiSelection.insert(ClipboardType.text.id)
        multiSelection.insert(ClipboardType.image.id)
        multiSelection.insert(ClipboardType.fileFolder.id)
        multiSelection.insert(ClipboardType.group.id)
    }
    
    private func removeAllButMe(id: UUID?) {
        for ids in multiSelection {
            if ids != id {
                multiSelection.remove(ids)
            }
        }
    }
}
