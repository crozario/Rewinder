//
//  MainViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/21/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import AudioKit

class MainViewController: UIViewController,UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    var viewControllers = [UIViewController]()
    var currentFrame = CGRect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let fViewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        let sViewController = storyboard.instantiateViewController(withIdentifier: "HighlightsViewController") as! HighlightsViewController
        viewControllers = [fViewController, sViewController]
        
        setupSlideScrollView()
    }
    
    func setupSlideScrollView() {
        scrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(viewControllers.count), height: view.frame.height)
        
        scrollView.isPagingEnabled = true
		scrollView.showsHorizontalScrollIndicator = false
        for i in 0 ..< viewControllers.count {
            currentFrame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            viewControllers[i].view.frame = currentFrame
            scrollView.addSubview(viewControllers[i].view)
        }
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}

        

