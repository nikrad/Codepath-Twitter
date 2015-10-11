//
//  MainViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 10/7/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, ContentViewControllerDelegate, MenuViewControllerDelegate {
  
  // MARK: - Outlets
  
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
  @IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!

  // MARK: - Properties
  
  private var menuOpen = false
  private var contentViewTap: UITapGestureRecognizer!
  private var contentViewRestingX: CGFloat!
  private var selectedNavigationOption = NavigationOption.Timeline
  private var contentViewController: UIViewController! {
    willSet (newContentViewController) {
      let pan = UIPanGestureRecognizer(target: self, action: "didPanContentView:")
      
      if let oldContentViewController = contentViewController {
        oldContentViewController.willMoveToParentViewController(nil)
        oldContentViewController.view.removeFromSuperview()
        oldContentViewController.removeFromParentViewController()
        oldContentViewController.view.removeGestureRecognizer(pan)
      }

      // Add the contentViewController to contentView
      self.addChildViewController(newContentViewController)
      newContentViewController.view.frame = self.contentView.bounds
//      newContentViewController.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
      self.contentView.addSubview(newContentViewController.view)
      newContentViewController.didMoveToParentViewController(self)
      
      // Set up swiping handler
      newContentViewController.view.addGestureRecognizer(pan)
      
      // Set the contentViewController's delegate to MainViewController to receive tap events
      // on the hamburger menu
      let navVC = newContentViewController as! UINavigationController
      let contentVC = navVC.viewControllers[0] as! ContentViewController
      contentVC.delegate = self
    }
  }
  
  // MARK: - Initializer
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set up the appearance of the navigation bar
    let navigationBarAppearance = UINavigationBar.appearance()
    navigationBarAppearance.barTintColor = UIColor(red: 0.33, green: 0.67, blue: 0.93, alpha: 1.0)
    navigationBarAppearance.tintColor = UIColor.whiteColor()
    navigationBarAppearance.translucent = false
    navigationBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]

    // Add the menu view controller
    let menuVC = storyboard!.instantiateViewControllerWithIdentifier("MenuViewController") as! MenuViewController
    menuVC.delegate = self
    self.addChildViewController(menuVC)
    menuVC.view.frame = self.view.bounds
//    menuVC.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    self.view.addSubview(menuVC.view)
    menuVC.didMoveToParentViewController(self)

    // Set up contentView
    self.contentView.center = self.view.center
    self.contentView.bounds = self.view.bounds
    self.view.bringSubviewToFront(contentView)

    // Add the view controller to the contentView
    self.contentViewController = storyboard?.instantiateViewControllerWithIdentifier("TimelineNavigationController")
    
    // Add the content view tap handler
    self.contentViewTap = UITapGestureRecognizer(target: self, action: "didTapContentView:")
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
  // MARK: - Action handlers
  
  func didTapContentView(sender: UITapGestureRecognizer) {
    switch (sender.state) {
    case .Ended:
      self.animateCloseMenu()
    default: ()
    }
  }
  
  func didPanContentView(sender: UIPanGestureRecognizer) {
    switch (sender.state) {
    case .Began:
      self.contentViewRestingX = self.contentView.frame.origin.x
    case .Changed:
      let dragX = sender.translationInView(self.view).x + contentViewRestingX
      // Don't allow swiping the contentView off the left side of the screen
      if dragX > 0 {
        contentViewLeftConstraint.constant = dragX
        contentViewRightConstraint.constant = dragX * -1
      }
    case .Ended, .Cancelled:
      let dragX = sender.locationInView(self.view).x
      if dragX > self.view.center.x {
        animateOpenMenu()
      } else {
        animateCloseMenu()
      }
    default: ()
    }
  }
  
  // MARK: - Animations
  
  func animateCloseMenu() {
    UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
      self.contentViewLeftConstraint.constant = 0
      self.contentViewRightConstraint.constant = 0
      self.contentView.layoutIfNeeded()
    }) { (finished) -> Void in
        self.menuOpen = false
        self.contentViewController.view.removeGestureRecognizer(self.contentViewTap)
    }
  }
  
  func animateOpenMenu() {
    UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
      let offset = self.view.frame.width - 50.0
      self.contentViewLeftConstraint.constant = offset
      self.contentViewRightConstraint.constant = offset * -1.0
      self.contentView.layoutIfNeeded()
    }) { (finished) -> Void in
      self.menuOpen = true
      self.contentViewController.view.addGestureRecognizer(self.contentViewTap)
    }
  }
  
  // MARK: - ContentViewControllerDelegate
  
  func contentViewController(contentViewController: ContentViewController, didTapHamburgerMenu: UIBarButtonItem) {
    if self.menuOpen == true {
      animateCloseMenu()
    } else {
      animateOpenMenu()
    }
  }
  
  // Mark: - MenuViewControllerDelegate
  
  func menuViewController(menuViewController: MenuViewController, didSelectOption navigationOption: NavigationOption) {
    if navigationOption == NavigationOption.SignOut {
      User.currentUser?.logout()
    } else {
      animateCloseMenu()      
      if self.selectedNavigationOption != navigationOption {
        self.selectedNavigationOption = navigationOption
        switch (navigationOption) {
        case .Timeline:
          self.contentViewController = storyboard!.instantiateViewControllerWithIdentifier("TimelineNavigationController")
        case .Profile:
          self.contentViewController = storyboard!.instantiateViewControllerWithIdentifier("ProfileNavigationController")
        case .Mentions:
          self.contentViewController = storyboard!.instantiateViewControllerWithIdentifier("MentionsNavigationController")
        default: ()
        }
      }
    }
  }
}
