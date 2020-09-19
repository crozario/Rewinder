//
//  PageViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class InfoPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	//    let pageControl = UIPageControl()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.dataSource = self
		self.delegate = self
		
		let firstViewController = subViewControllers.first
		self.setViewControllers([firstViewController!], direction: .forward, animated: true, completion: nil)
		
		
		
		if let myView = view?.subviews.first as? UIScrollView {
			myView.canCancelContentTouches = false
		}
		
		
		
	}
	
	lazy var subViewControllers: [UIViewController] = {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		var pages: [UIViewController] = []
		
		let initial = storyboard.instantiateViewController(withIdentifier: "InitialInfoViewController") as! InitialInfoViewController
		let expand = storyboard.instantiateViewController(withIdentifier: "ExpandInfoViewController") as! ExpandInfoViewController
		let background = storyboard.instantiateViewController(withIdentifier: "BackgroundInfoViewController") as! BackgroundInfoViewController
		let record = storyboard.instantiateViewController(withIdentifier: "RecordInfoViewController") as! RecordInfoViewController
		
		pages.append(initial)
		pages.append(expand)
		pages.append(background)
		pages.append(record)
		
		// delegates
		initial.delegate = self
		expand.delegate = self
		background.delegate = self
		record.delegate = self
		
		return pages
	}()
	
	
	func presentationCount(for pageViewController: UIPageViewController) -> Int {
		return subViewControllers.count
	}
	
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		guard let viewControllerIndex = subViewControllers.firstIndex(of: viewController) else {
			return nil
		}
		
		let previousViewControllerIndex = viewControllerIndex - 1
		
		guard previousViewControllerIndex >= 0 else {
			return nil
		}
		
		guard subViewControllers.count > previousViewControllerIndex else {
			return nil
		}
		
		return subViewControllers[previousViewControllerIndex]
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		guard let viewControllerIndex = subViewControllers.firstIndex(of: viewController) else {
			return nil
		}
		
		let nextViewControllerIndex = viewControllerIndex + 1
		
		
		guard nextViewControllerIndex  < subViewControllers.count else {
			return nil
		}
		
		guard subViewControllers.count > nextViewControllerIndex else {
			return nil
		}
		
		return subViewControllers[nextViewControllerIndex]
	}
}

// Page extensions to go to next page and skip to last page
extension InfoPageViewController: InitialInfoPageDelegate {
	func nextTapped(currentViewController: InitialInfoViewController) {
		print("\(#function) InitialInfoViewController")
	}
	
	func skipTapped(currentViewController: InitialInfoViewController) {
		print("\(#function) InitialInfoViewController")
	}
}

extension InfoPageViewController: ExpandInfoPageDelegate {
	func nextTapped(currentViewController: ExpandInfoViewController) {
		print("\(#function) ExpandInfoViewController")
	}
	
	func skipTapped(currentViewController: ExpandInfoViewController) {
		print("\(#function) ExpandInfoViewController")
	}
}

extension InfoPageViewController: BackgroundInfoPageDelegate {
	func nextTapped(currentViewController: BackgroundInfoViewController) {
		print("\(#function) BackgroundInfoViewController")
	}
	
	func skipTapped(currentViewController: BackgroundInfoViewController) {
		print("\(#function) BackgroundInfoViewController")
	}
}

extension InfoPageViewController: RecordInfoPageDelegate {
	func nextTapped(currentViewController: RecordInfoViewController) {
		print("\(#function) RecordInfoViewController")
	}
	
	func skipTapped(currentViewController: RecordInfoViewController) {
		print("\(#function) RecordInfoViewController")
	}
}











