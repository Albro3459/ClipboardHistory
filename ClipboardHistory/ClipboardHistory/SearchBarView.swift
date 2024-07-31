//
//  SearchBarView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/21/24.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState private var isTextFieldFocused: Bool

    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)

                TextField("Search", text: $searchText)
                    .focused($isTextFieldFocused)
                    .padding(.trailing, searchText.isEmpty ? 10 : 0)

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isTextFieldFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.top, 3)
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


private func search() {
    
}
