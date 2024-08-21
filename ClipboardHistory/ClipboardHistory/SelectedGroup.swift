//
//  SelectedGroup.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/9/24.
//

import Foundation

class SelectedGroup: ObservableObject, Equatable, Hashable {
    
    var group: ClipboardGroup
    @Published var selectedItem: ClipboardItem?
    @Published var isExpanded: Bool
//    @Published var showAfterDelete: Bool
    
    init(group: ClipboardGroup, selectedItem: ClipboardItem? = nil, isExpanded: Bool = false/*, showAfterDelete: Bool = false*/) {
        self.group = group
        self.selectedItem = selectedItem
        self.isExpanded = isExpanded
//        self.showAfterDelete = showAfterDelete
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
