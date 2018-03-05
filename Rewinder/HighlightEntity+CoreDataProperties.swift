//
//  HighlightEntity+CoreDataProperties.swift
//  
//
//  Created by Haard Shah on 3/4/18.
//
//

import Foundation
import CoreData


extension HighlightEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HighlightEntity> {
        return NSFetchRequest<HighlightEntity>(entityName: "HighlightEntity")
    }

    @NSManaged public var dateandtime: NSDate?
    @NSManaged public var title: String?
    @NSManaged public var duration: Float
    @NSManaged public var audioURL: NSURL?

}
