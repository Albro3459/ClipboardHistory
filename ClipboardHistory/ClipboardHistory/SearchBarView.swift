//
//  SearchBarView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/21/24.
//

import SwiftUI

struct SearchBarView: View {
    @State private var searchText = ""
    @State private var isModalPresented = false
    
    var body: some View {
        HStack {
            Button(action: {
                isModalPresented.toggle()
            }) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(BorderlessButtonStyle())
            .sheet(isPresented: $isModalPresented) {
                SearchModalView(searchText: $searchText, isPresented: $isModalPresented)
            }
        }
    }
}

struct SearchModalView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Close") {
                    isPresented = false
                }
                .padding()
                Button("Search") {
                    search()
                }
                .padding()
            }
        }
        .frame(width: 250, height: 125)
//        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

private func search() {
    
}

