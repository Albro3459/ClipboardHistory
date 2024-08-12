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
        // Convert NSSet to Set<ClipboardItem>
        let set = items as? Set<ClipboardItem> ?? []
    
        //I want to sort by type, text, images, then files then folders, and in these types, I want by content alphabetically
        let typePriority: [String: Int] = [
            "text": 1,
            "image": 2,
            "file": 3,
            "folder": 4,
            "alias": 5,
            "removable": 6,
            "symlink": 7
        ]
        
        return set.sorted {
            // First compare by content
            let contentOrder = ($0.content ?? "").lowercased().compare(($1.content ?? "").lowercased())
            if contentOrder == .orderedSame {
                // If content is the same, then sort by type
                let typeOrder1 = typePriority[$0.type ?? ""] ?? 999
                let typeOrder2 = typePriority[$1.type ?? ""] ?? 999
                return typeOrder1 < typeOrder2
            }
            return contentOrder == .orderedAscending
        }
    }
    
    func GetSelecGroupObj(_ group: ClipboardGroup?, list: [SelectedGroup]) -> SelectedGroup? {
        if let group = group {
            
            for selection in list {
                if selection.group == group {
                    return selection
                }
            }
            
            return SelectedGroup(group: group, selectedItem: nil)

        }
        else {
            return nil
        }
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
