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
    @Binding var searchText: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                    .onTapGesture {
                        isTextFieldFocused = false
                    }

                ClearTextField(placeholder: "Search", text: $searchText)
                    .focused($isTextFieldFocused)
                    .padding(.top, 2)
                    .padding(.bottom, 4)
                    .padding(.trailing, searchText.isEmpty ? 21 : 0)
                    .help("Search Bar")
                    

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isTextFieldFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.white)
                            .padding(.trailing, -2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Clear Search Text")
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                isTextFieldFocused = false
            }
        }
    }
}

struct ClearTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.placeholderString = placeholder
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
//                    .zIndex(1)
                Text("Filter by type: ")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 5)
//                    .zIndex(2)
            }
            .frame(maxWidth: .infinity)
//            .zIndex(2)
            
            
            List(clipboardManager.types, id: \.id, selection: $multiSelection) { type in
                HStack {
                    Spacer()  // Pushes the text to the center
                    Text(type.name)
                        .foregroundColor(.white)
                        .fontWeight(type.name == "Select All" ? .bold : .medium)
                    Spacer()  // Ensures the text stays centered
                }
                .foregroundColor(.white)
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
//            .zIndex(0)
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
