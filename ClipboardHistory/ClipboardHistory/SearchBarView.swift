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
            return "text"
        case ClipboardType.image.id:
            return "image"
        case ClipboardType.fileFolder.id:
            return "fileFolder"
        default:
            return ""
        }
    }
    
    static let text = ClipboardType(id: UUID(), name: "text")
    static let image = ClipboardType(id: UUID(), name: "image")
    static let fileFolder = ClipboardType(id: UUID(), name: "file / folder")
}

struct TypeDropDownMenu: View {
    let types = [
        ClipboardType.text,
        ClipboardType.image,
        ClipboardType.fileFolder
    ]
    
    @Binding var multiSelection: Set<UUID>
    
    var body: some View {
        ZStack(alignment: .top){
            ZStack {
                Rectangle()
                    .fill(.background)
                    .frame(height: 26)
                    .zIndex(1)
                Text("Filter by type: ")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 2)
                    .zIndex(2)
            }
            .frame(maxWidth: .infinity)
            .zIndex(2)
            
            List(types, id: \.id, selection: $multiSelection) { type in
                Text(type.name)
                    .foregroundColor(.white)
                    .listRowBackground(Color.gray.opacity(0.25))
                    .onTapGesture {
                        if multiSelection.contains(type.id) {
                            multiSelection.remove(type.id)
                        } else {
                            multiSelection.insert(type.id)
                        }
                    }
            }
            .scrollDisabled(true)
            .padding(.top, 16)
            .zIndex(0)
        }
    }
}
