//
//  SearchBarView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/21/24.
//

import SwiftUI
import AppKit

struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
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
//                    search(searchText: searchText)
                    
                    Button(action: {
                        searchText = ""
                        isTextFieldFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, -2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            setUpKeyboardHandling()
            DispatchQueue.main.async {
                isTextFieldFocused = false
            }
        }
    }
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            
            if event.type == .keyDown {
                switch event.keyCode {
                case 3:
                    if event.modifierFlags.contains(.command) {
                        // Handle Command + F
                        DispatchQueue.main.async {
                            isTextFieldFocused = true
                        }
                        return nil // no more beeps
                    }
                case 53:
                    // escape key
                    DispatchQueue.main.async {
                        isTextFieldFocused = false
                    }
                    return nil
                default:
                    break
                }
            }
            return event
        }
    }

}

struct ClipboardType: Identifiable {
    let id = UUID()
    let name: String
}

struct TypeDropDownMenu: View {
    
    let types = [
        ClipboardType(name: "text"),
        ClipboardType(name: "image"),
        ClipboardType(name: "file/folder")
    ]
    
//    @State private var selectedType: String = "any"
    @Binding var multiSelection: Set<UUID>

    var body: some View {
        VStack {
//            Picker("", selection: $selectedType) {
//                ForEach(types, id: \.self) { type in
//                    Text(type)
//                }
//            }
            List(types, id: \.id, selection: $multiSelection) { type in
                Text(type.name)
                    .tag(type.id)
            }
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//        .background(Color(.lightGray).opacity(0.4))

    }
}

struct ClearTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isBordered = false // Removes border
        textField.drawsBackground = false // Ensures the background is clear
        textField.placeholderString = placeholder // Sets the placeholder text
        textField.delegate = context.coordinator // Assigns delegate
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.focusRingType = .none // Disables the focus ring


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
