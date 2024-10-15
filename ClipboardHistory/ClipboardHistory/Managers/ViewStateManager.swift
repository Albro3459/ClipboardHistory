//
//  ViewStateManager.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 10/15/24.
//

import Foundation


class ViewStateManager: ObservableObject {
    static let shared = ViewStateManager()
    
    @Published var selectList: [SelectedGroup] = []
    
    @Published var searchText: String = ""
    @Published var isSearchFocused: Bool = false
    @Published var justSearched: Bool = false
    
    @Published var scrollToTop: Bool = false
    @Published var scrollToBottom: Bool = false
    @Published var justScrolledToTop: Bool = true
    
    private init() { }
}
