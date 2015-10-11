//
//  User.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 9/30/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit

var _currentUser: User?
let currentUserKey = "kCurrentUserKey"
let userDidLoginNotification = "userDidLoginNotification"
let userDidLogoutNotification = "userDidLogoutNotification"

class User: NSObject {
  var name: String?
  var screename: String?
  var profileImageUrl: NSURL?
  var profileBannerImageUrl: NSURL?
  var profileColor: String?
  var tagline: String?
  var dictionary: NSDictionary
  var protected: Bool?
  var tweetCount: Int?
  var followingCount: Int?
  var followersCount: Int?
  
  init(dictionary: NSDictionary) {
    self.dictionary = dictionary

    self.name = dictionary["name"] as? String
    self.screename = dictionary["screen_name"] as? String
    self.protected = dictionary["protected"] as? Bool
    self.tweetCount = dictionary["statuses_count"] as? Int
    self.followingCount =  dictionary["friends_count"] as? Int
    self.followersCount =  dictionary["followers_count"] as? Int
    self.profileColor = dictionary["profile_link_color"] as? String
    if let profileBanner = dictionary["profile_banner_url"] {
      self.profileBannerImageUrl = NSURL(string: profileBanner as! String)
    }

    // Get a larger version of the profile image
    var profileImageUrlString = dictionary["profile_image_url"] as! String
    let range = profileImageUrlString.rangeOfString("_normal\\.", options: .RegularExpressionSearch)
    if let range = range {
      profileImageUrlString = profileImageUrlString.stringByReplacingCharactersInRange(range, withString: "_bigger.")
    }
    self.profileImageUrl = NSURL(string: profileImageUrlString)
  }
  
  func logout() {
    User.currentUser = nil
    TwitterClient.sharedInstance.requestSerializer.removeAccessToken()
    
    NSNotificationCenter.defaultCenter().postNotificationName(userDidLogoutNotification, object: nil)
  }
  
  class var currentUser: User? {
    get {
      if _currentUser == nil {
        let data = NSUserDefaults.standardUserDefaults().objectForKey(currentUserKey) as? NSData
        if data != nil {
          let dictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
          _currentUser = User(dictionary: dictionary)
        }
      }
    
      return _currentUser
    }
    set(user) {
      _currentUser = user
      
      // Should use NSCoding
      if _currentUser != nil {
        let data = try! NSJSONSerialization.dataWithJSONObject(user!.dictionary, options: [])
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: currentUserKey)
      } else {
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: currentUserKey)
      }
      
      NSUserDefaults.standardUserDefaults().synchronize()
    }
  }
}
