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
    var isExpanded: Bool
    
    init(group: ClipboardGroup, selectedItem: ClipboardItem? = nil, isExpanded: Bool = false) {
        self.group = group
        self.selectedItem = selectedItem
        self.isExpanded = isExpanded
    }
    
    static func == (groupA: SelectedGroup, groupB: SelectedGroup) -> Bool {
        return groupA.group.objectID == groupB.group.objectID &&
        groupA.selectedItem?.content == groupB.selectedItem?.content &&
                groupA.group.count == groupB.group.count &&
        groupA.group.timeStamp == groupB.group.timeStamp
//            && groupA.isExpanded == groupB.isExpanded
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(group))
        if let item = selectedItem {
            hasher.combine(ObjectIdentifier(item))
        }
    }
}
