//
//  ClipboardGroup+CoreDataProperties.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/7/24.
//
//

import Foundation
import CoreData


extension ClipboardGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClipboardGroup> {
        return NSFetchRequest<ClipboardGroup>(entityName: "ClipboardGroup")
    }

    @NSManaged public var timeStamp: Date?
    @NSManaged public var count: Int16
    @NSManaged public var items: NSSet?

    public var itemsArray: [ClipboardItem] {
        let set = items as? Set<ClipboardItem> ?? []
        
        let typePriority: [String: Int] = [
            "text": 1,
            "image": 2,
            "file": 3,
            "folder": 4,
            "alias": 5,
            "removable": 6,
            "symlink": 7
        ]
        
        return set.sorted { itemA, itemB in
            // Compares 2 items by type based on priority number
            let typeOrder1 = typePriority[itemA.type ?? "unknown"] ?? 999
            let typeOrder2 = typePriority[itemB.type ?? "unknown"] ?? 999

            // If types are the same, sort by content alphabetically
            if typeOrder1 == typeOrder2 {
                // true means itemA before itemB, false means the other way around
                return (itemA.content ?? "").lowercased() < (itemB.content ?? "").lowercased()
            }
            // true means itemA before itemB, false means the other way around
            return typeOrder1 < typeOrder2
        }
    }
    
    func GetSelecGroupObj(_ group: ClipboardGroup?, list: [SelectedGroup]) -> SelectedGroup? {
        if let group = group {
            
            for selection in list {
                if selection.group == group {
                    return selection
                }
            }
            return SelectedGroup(group: group, selectedItem: nil, isExpanded: findExpandedState(for: group, selectList: list))

        }
        else {
            return nil
        }
    }
    
    private func findExpandedState(for inputGroup: ClipboardGroup, selectList: [SelectedGroup]) -> Bool {
        // if this group was already in selectList, return its isExpanded
        return selectList.first(where: { $0.group == inputGroup })?.isExpanded ?? false
    }
}

// MARK: Generated accessors for items
extension ClipboardGroup {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: ClipboardItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: ClipboardItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension ClipboardGroup : Identifiable {

}
