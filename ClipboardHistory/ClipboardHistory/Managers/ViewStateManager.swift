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
    
    @Published var deleteOccurred: Bool = false
    @Published var showingAlert: Bool = false
    
    private init() { }
    
    func deleted() {
        if self.deleteOccurred { return } // dont overlap alerts
        DispatchQueue.main.async {
            self.deleteOccurred = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.deleteOccurred = false
            }
        }
    }
}
