//
//  ClipboardItem+CoreDataProperties.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/7/24.
//
//

import Foundation
import CoreData


extension ClipboardItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }

    @NSManaged public var content: String?
    @NSManaged public var filePath: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var imageHash: String?
    @NSManaged public var timeStamp: Date?
    @NSManaged public var type: String?
    @NSManaged public var group: ClipboardGroup?

}

extension ClipboardItem : Identifiable {

}
