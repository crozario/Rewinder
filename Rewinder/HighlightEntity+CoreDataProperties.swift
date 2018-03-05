//
//  HighlightEntity+CoreDataProperties.swift
//  
//
//  Created by Haard Shah on 3/5/18.
//
//

import Foundation
import CoreData


extension HighlightEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HighlightEntity> {
        return NSFetchRequest<HighlightEntity>(entityName: "HighlightEntity")
    }

    @NSManaged public var audioURL: NSURL?
    @NSManaged public var dateandtime: NSDate?
    @NSManaged public var duration: Double
    @NSManaged public var title: String?

	func printHighlightInfo() {
		print("Title: \(title!.description), Date: \(dateandtime!.description), Duration: \(duration.description)")
	}
	
	func printHighlightInfoWithURL() {
		print("Title: \(title!.description), Date: \(dateandtime!.description), Duration: \(duration.description), URL: \(String(describing: audioURL!.absoluteString))")
	}
}
