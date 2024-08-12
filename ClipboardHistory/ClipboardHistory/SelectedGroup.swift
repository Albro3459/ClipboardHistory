//
//  SelectedGroup.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/9/24.
//

import Foundation

class SelectedGroup: Equatable, Hashable {
    
    var group: ClipboardGroup
    var selectedItem: ClipboardItem?
    
    init(group: ClipboardGroup, selectedItem: ClipboardItem? = nil) {
        self.group = group
        self.selectedItem = selectedItem
    }
    
    static func == (groupA: SelectedGroup, groupB: SelectedGroup) -> Bool {
        return groupA.group == groupB.group && groupA.selectedItem == groupB.selectedItem
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(group))
        if let item = selectedItem {
            hasher.combine(ObjectIdentifier(item))
        }
    }
}
