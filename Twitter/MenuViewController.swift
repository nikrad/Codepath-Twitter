//
//  MenuViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 10/7/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit

@objc protocol MenuViewControllerDelegate {
  optional func menuViewController(menuViewController: MenuViewController, didSelectOption navigationOption: NavigationOption)
}

@objc enum NavigationOption: Int {
  case Timeline
  case Profile
  case Mentions
  case SignOut
}

class MenuViewController: UIViewController {
  
  @IBOutlet weak var timelineButton: UIButton!
  @IBOutlet weak var profileButton: UIButton!
  @IBOutlet weak var mentionsButton: UIButton!
  @IBOutlet weak var profileImageView: UIImageView!
  
  @IBOutlet weak var scrollView: UIScrollView!
  
  weak var delegate: MenuViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.scrollView.delaysContentTouches = false
    self.scrollView.scrollsToTop = false
    
    self.profileImageView.setImageWithURL(User.currentUser?.profileImageUrl!)
    self.profileImageView.layer.cornerRadius = 5.0
    self.profileImageView.layer.borderWidth = 2.0
    self.profileImageView.layer.borderColor = UIColor.darkGrayColor().CGColor
    self.profileImageView.clipsToBounds = true
  }
  
  func highlightSelectedNavigationButton(button: UIButton) {
    timelineButton.selected = false
    profileButton.selected = false
    mentionsButton.selected = false
    button.selected = true
  }

  @IBAction func onTapTimeline(sender: UIButton) {
    self.highlightSelectedNavigationButton(sender)
    self.delegate?.menuViewController!(self, didSelectOption: .Timeline)
  }
  
  @IBAction func onTapProfile(sender: UIButton) {
    self.highlightSelectedNavigationButton(sender)
    self.delegate?.menuViewController!(self, didSelectOption: .Profile)
  }
  
  @IBAction func onTapMentions(sender: UIButton) {
    self.highlightSelectedNavigationButton(sender)
    self.delegate?.menuViewController!(self, didSelectOption: .Mentions)
  }
  
  @IBAction func onTapSignOut(sender: AnyObject) {
    self.delegate?.menuViewController!(self, didSelectOption: .SignOut)
  }
}
