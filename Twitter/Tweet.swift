//
//  Tweet.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 9/30/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit

class Tweet: NSObject {
  var user: User?
  var idString: String?
  var text: String?
  var createdAtRawString: String?
  var createdAt: NSDate?
  var userHasFavorited: Bool?
  var userHasRetweeted: Bool?
  var retweetCount: Int?
  var favoriteCount: Int?
  var isReply: Bool?
  var replyToScreenName: String?
  var isRetweet: Bool?
  var retweetSourceTweet: Tweet?
  var currentUserRetweetIdString: String?
  
  // Use a cached an instance of NSDateFormatter to improve performance
  class var dateFormatterInstance: NSDateFormatter {
    struct Static {
      static let formatterInstance = NSDateFormatter()
    }

    Static.formatterInstance.dateFormat = "EEE MMM d HH:mm:ss Z y"
    return Static.formatterInstance
  }
  
  init(dictionary: NSDictionary) {
    super.init()

    user = User(dictionary: dictionary["user"] as! NSDictionary)
    idString = dictionary["id_str"] as? String
    text = dictionary["text"] as? String
    createdAtRawString = dictionary["created_at"] as? String
    userHasFavorited = dictionary["favorited"] as? Bool
    userHasRetweeted = dictionary["retweeted"] as? Bool
    retweetCount = dictionary["retweet_count"] as? Int
    favoriteCount = dictionary["favorite_count"] as? Int
    if let retweetStatus = dictionary["retweeted_status"] as? NSDictionary {
      isRetweet = true
      retweetSourceTweet = Tweet(dictionary: retweetStatus)
    }
    if let inReplyToScreenName = dictionary["in_reply_to_screen_name"] as? String {
      isReply = true
      replyToScreenName = inReplyToScreenName
    }
    createdAt = Tweet.dateFormatterInstance.dateFromString(createdAtRawString!)
    if let currentUserRetweet = dictionary["current_user_retweet"] as? NSDictionary {
      currentUserRetweetIdString = currentUserRetweet["id_str"] as? String
    }
  }

  class func tweetsWithArray(array: [NSDictionary]) -> [Tweet] {
    var tweets = [Tweet]()
    for dictionary in array {
      tweets.append(Tweet(dictionary: dictionary))
    }
    
    return tweets
  }
  
}
