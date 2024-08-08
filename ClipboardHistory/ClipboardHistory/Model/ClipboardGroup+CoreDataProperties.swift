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
