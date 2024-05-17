//
//  ClipboardItem+CoreDataProperties.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/17/24.
//
//

import Foundation
import CoreData


extension ClipboardItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }

    @NSManaged public var content: String?
    @NSManaged public var type: String?
    @NSManaged public var timestamp: Date?

}

extension ClipboardItem : Identifiable {

}
