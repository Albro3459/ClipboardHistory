//
//  SelectListManager.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 9/3/24.
//

import Foundation

class SelectListManager : ObservableObject {
    static let shared = SelectListManager()
    
    @Published var selectList: [SelectedGroup] = []
    
    private init() { }
}
