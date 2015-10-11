//
//  ContentViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 10/7/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit

@objc protocol ContentViewControllerDelegate {
  optional func contentViewController(contentViewController: ContentViewController, didTapHamburgerMenu: UIBarButtonItem)
}

class ContentViewController: UIViewController {
  
  weak var delegate: ContentViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if self.navigationController?.viewControllers.count == 1 {
      // Add the hamburger menu as the left bar button item of the view controller's navigation controller
      self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "Hamburger"), style: .Plain, target: self, action: "onHamburgerTapped:")
    }
  }
  
  func onHamburgerTapped(sender: UIBarButtonItem) {
    self.delegate?.contentViewController!(self, didTapHamburgerMenu: sender)
  }
}
