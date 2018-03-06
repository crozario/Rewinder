//
//  HighlightEntity+CoreDataProperties.swift
//  Rewinder
//
//  Created by Haard Shah on 3/6/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//
//

import Foundation
import CoreData


extension HighlightEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HighlightEntity> {
        return NSFetchRequest<HighlightEntity>(entityName: "HighlightEntity")
    }

    @NSManaged public var fileName: String?
    @NSManaged public var dateandtime: NSDate?
    @NSManaged public var duration: Double
    @NSManaged public var title: String?

	func printHighlightInfo() {
		print("Title: \(title!.description), Date: \(dateandtime!.description), Duration: \(duration.description)")
	}
	
	func printHighlightInfoWithFilename() {
		print("Title: \(title!.description), Date: \(dateandtime!.description), Duration: \(duration.description), Filename: \(fileName!.description)")
	}
}
