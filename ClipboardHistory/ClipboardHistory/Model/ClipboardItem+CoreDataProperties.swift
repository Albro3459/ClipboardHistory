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
    
    // text: just text, images and files: file name, imageData: "probablyScreenshot"
    @NSManaged public var content: String?
    @NSManaged public var type: String?
    @NSManaged public var timeStamp: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var filePath: String? // full file path if available
    @NSManaged public var imageHash: String?

}

extension ClipboardItem : Identifiable {

}
