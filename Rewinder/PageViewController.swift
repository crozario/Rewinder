//
//  PageViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        
        if let firstViewController = subViewControllers.first {
            self.setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
 

    }
    
    lazy var subViewControllers: [UIViewController] = {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let homeViewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
        let highlightsViewController = storyboard.instantiateViewController(withIdentifier: "HighlightsViewController")
        let settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        
        
        
        return [homeViewController, highlightsViewController, settingsViewController]
    }()

    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return subViewControllers.count
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = subViewControllers.index(of: viewController) else {
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
        guard let viewControllerIndex = subViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextViewControllerIndex = viewControllerIndex + 1
        
        guard subViewControllers.count != nextViewControllerIndex else {
            return nil
        }
        
        guard subViewControllers.count > nextViewControllerIndex else {
            return nil
        }
        
        return subViewControllers[nextViewControllerIndex]
    }
}









