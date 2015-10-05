//
//  ViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 9/28/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func onLogin(sender: AnyObject) {
    // Put this in the user class
    TwitterClient.sharedInstance.loginWithCompletion() {
      (user: User?, error: NSError?) in
      if user != nil {
        self.performSegueWithIdentifier("loginSegue", sender: self)
      } else {
        // handle login error
      }
    }
  }

}

