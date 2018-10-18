//
//  Highlights.swift
//  Rewinder
//
//  Created by Haard Shah on 9/20/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Highlights {
	
	/*
	Looks like this
	twoDarr = [
	[date, highlighttitle, ..., highlighttitle]
	[date, highlighttitle]
	...
	[date, highlighttitle, ..., highlighttitle]
	]
	* the most recent titles are at the top
	* each row in the 2D array is a section on tableview
	* col0 is date in all rows
	* col1-x is the highlighttitles
	*/
	var twoDarr = [[String]]()
	
	/*
	Thes are the four attributes stored inside CoreData Model (in HighlightEntity)
	*/
	let attribute_dateandtime: String = "dateandtime"
	let attribute_duration: String = "duration"
	let attribute_fileName: String = "fileName"
	let attribute_title: String = "title"
	
	let context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	init() {
		setHighlightTitlesTwoD()
	}
	
	private func setHighlightTitlesTwoD() {
		let results = self.getHighlightsList()
		
		for element in results {
			let managedObj = element as! NSManagedObject
			_ = appendTo2Darr(managedObject: managedObj)
		}
	}
	
	func getHighlightsList() -> [NSFetchRequestResult] {
		let entityDescription = NSEntityDescription.entity(forEntityName: "HighlightEntity", in: context)
		let request: NSFetchRequest<HighlightEntity> = HighlightEntity.fetchRequest()
		let sortDescriptor = NSSortDescriptor(key: attribute_dateandtime, ascending: true)
		
		request.entity = entityDescription
		request.sortDescriptors = [sortDescriptor]
		
		var results = [NSFetchRequestResult]()
		do {
			results = try context.fetch(request as! NSFetchRequest<NSFetchRequestResult>)
		} catch let error {
			print (error.localizedDescription)
		}
		return results
	}
	
	func appendTo2Darr(managedObject: NSManagedObject) -> Bool {
		
		var newSectionInserted: Bool = false
		
		let date: Date = managedObject.value(forKey: attribute_dateandtime) as! Date
		let currDate: String = getDate(date: date)
		let title: String = managedObject.value(forKey: attribute_title) as! String
		
		if !twoDarr.isEmpty {
			// should never have twoDarr[0].count == 0 so don't need to check
			let prevDate: String = twoDarr[0][0]
			
			if currDate == prevDate {
				twoDarr[0].insert(title, at: 1)
				newSectionInserted = false
			}
			else {
				twoDarr.insert([currDate], at: 0)
				twoDarr[0].insert(title, at: 1)
				newSectionInserted = true
			}
		} else {
			twoDarr.insert([currDate], at: 0)
			twoDarr[0].insert(title, at: 1)
			newSectionInserted = true
		}
		return newSectionInserted
	}
	
	private func getDate(date: Date) -> String{
		// in "en_US" format; ex: Mar 15, 2018
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		dateFormatter.locale = Locale(identifier: "en_US")
		
		return dateFormatter.string(from: date)
	}
	
	// MARK: TwoDarr Getters
	func getHighlightTitle(indexPath: IndexPath) -> String{
		return twoDarr[indexPath.section][indexPath.row + 1]
	}
	
	func setHighlightTitle(indexPath: IndexPath, title: String) {
		twoDarr[indexPath.section][indexPath.row + 1] = title
	}
	
	func removeHighlightTitle(indexPath: IndexPath) {
		// should you check whether this is the last item in section
		twoDarr[indexPath.section].remove(at: indexPath.row + 1)
	}
	
	
}
