//
//  TwitterClient.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 9/28/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit
import SwiftyJSON

let twitterConsumerKey = "h4kzNuHpUKTqIy80uu2opRKV5"
let twitterConsumerSecret = "VvCMMUlI8x80C6yuJrlhHMJdGk8G5b8jYaKcLYnsDZiK363VcP"
let twitterBaseURL = NSURL(string: "https://api.twitter.com")

class TwitterClient: BDBOAuth1RequestOperationManager {
  
  var loginCompletion: ((user: User?, error: NSError?) -> ())?
  
  class var sharedInstance: TwitterClient {
    struct Static {
      static let instance = TwitterClient(baseURL: twitterBaseURL, consumerKey: twitterConsumerKey, consumerSecret: twitterConsumerSecret)
    }
    
    return Static.instance
  }
  
  func tweet(tweetText: String, inReplyToTweetIdString: String?, completion: (tweet: Tweet?, error: NSError?) -> ()) {
    var params = ["status": tweetText]
    if let inReplyToTweetIdString = inReplyToTweetIdString {
      params["in_reply_to_status_id"] = inReplyToTweetIdString
    }
    POST("1.1/statuses/update.json", parameters: params, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
      print("Posted tweet successfully!")
      let json = JSON(response)
      print(json.rawValue)
      let tweet = Tweet(dictionary: response as! NSDictionary)
      completion(tweet: tweet, error: nil)
    }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
        print("Failed to post tweet")
        print(error)
        completion(tweet: nil, error: error)
    })
  }
  
  func unretweet(tweet: Tweet, completion: (retweet: Tweet?, error: NSError?) -> ()) {
    assert(tweet.userHasRetweeted == true, "A user can't unretweet a tweet they haven't retweeted")
    
    let originalTweetId = tweet.retweetSourceTweet != nil ? tweet.retweetSourceTweet!.idString : tweet.idString
    
    GET("1.1/statuses/show/\(originalTweetId!).json", parameters: ["include_my_retweet": 1], success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
      print("Got full tweet")
      let json = JSON(response)
      print(json.rawValue)
      let tweet = Tweet(dictionary: response as! NSDictionary)
      let retweetId = tweet.currentUserRetweetIdString
      
      self.POST("1.1/statuses/destroy/\(retweetId!).json", parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
        print("Unretweet succeeded")
        let json = JSON(response)
        print(json.rawValue)
        let tweet = Tweet(dictionary: response as! NSDictionary)
        completion(retweet: tweet, error: nil)
      }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
        print("Unretweet failed")
        print(error)
        completion(retweet: nil, error: error)
      })
      
    }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
        print("Error getting full tweet")
        completion(retweet: nil, error: error)
    })
  }

  func retweet(tweetId: String, completion: (updatedTweet: Tweet?, error: NSError?) -> ()) {
    let urlString = "1.1/statuses/retweet/\(tweetId).json"
    print(urlString)
    POST(urlString, parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
      print("Request to \(urlString) succeeded")
      let json = JSON(response)
      print(json.rawValue)
      let tweet = Tweet(dictionary: response as! NSDictionary)
      completion(updatedTweet: tweet.retweetSourceTweet, error: nil)
    }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
      print("Request to \(urlString) failed")
      print(error)
      completion(updatedTweet: nil, error: error)
    })
  }
  
  func toggleFavorite(idString: String, userHasFavorited: Bool, completion: (updatedTweet: Tweet?, error: NSError?) -> ()) {
    let urlString = userHasFavorited == true ? "1.1/favorites/destroy.json" : "1.1/favorites/create.json"
    POST(urlString, parameters: ["id": idString], success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
//      print("Request to \(urlString) succeeded")
//      let json = JSON(response)
//      print(json.rawValue)
      let tweet = Tweet(dictionary: response as! NSDictionary)
      completion(updatedTweet: tweet, error: nil)
    }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
//      print("Request to \(urlString) failed")
//      print(error)
      completion(updatedTweet: nil, error: error)
    })
  }
  
  func mentionsTimelineWithParams(params: NSDictionary?, completion: (tweets: [Tweet]?, error: NSError?) -> ()) {
    GET("1.1/statuses/mentions_timeline.json", parameters: params, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
      let tweets = Tweet.tweetsWithArray(response as! [NSDictionary])
      completion(tweets: tweets, error: nil)
      
      }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
        print("error getting mentions timeline")
        self.GET("1.1/application/rate_limit_status.json", parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
          print(JSON(response).rawValue)
          }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
        })
        completion(tweets: nil, error: error)
    })
  }
  
  func userTimelineWithParams(params: NSDictionary?, completion: (tweets: [Tweet]?, error: NSError?) -> ()) {
    GET("1.1/statuses/user_timeline.json", parameters: params, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
      let tweets = Tweet.tweetsWithArray(response as! [NSDictionary])
      completion(tweets: tweets, error: nil)
    }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
      print("error getting user timeline")
      self.GET("1.1/application/rate_limit_status.json", parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
        print(JSON(response).rawValue)
        }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
      })
      completion(tweets: nil, error: error)
    })
  }
  
  func homeTimelineWithParams(params: NSDictionary?, completion: (tweets: [Tweet]?, error: NSError?) -> ()) {
//    let cachedDataUrl = NSURL(string: "https://gist.githubusercontent.com/nikrad/d0d733f3f2a8f815375a/raw/d3d33ff5997b3ec6b485aa66a4babcbe71273a56/timeline.json")
//    let request = NSURLRequest(URL: cachedDataUrl!)
//    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {(data, response, error) -> Void in
//      if let error = error {
//        // Error
//        print("Error fetching timeline")
//        completion(tweets: nil, error: error)
//      } else {
//        // Success
//        let json = JSON(data: data!)
//        let tweets = Tweet.tweetsWithArray(json.rawValue as! [NSDictionary])
//        completion(tweets: tweets, error: nil)
//      }
//    }
//    task.resume()

    GET("1.1/statuses/home_timeline.json", parameters: params, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
      let tweets = Tweet.tweetsWithArray(response as! [NSDictionary])
      completion(tweets: tweets, error: nil)
      
    }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
      print("error getting home timeline")
      self.GET("1.1/application/rate_limit_status.json", parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
        let json = JSON(response)
        print(json.rawValue)
        }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
      })
      completion(tweets: nil, error: error)
    })
  }
  
  func loginWithCompletion(completion: (user: User?, error: NSError?) -> ()) {
    loginCompletion = completion
    
    // Fetch request token and redirect to authorization page
    TwitterClient.sharedInstance.requestSerializer.removeAccessToken()
    TwitterClient.sharedInstance.fetchRequestTokenWithPath("oauth/request_token", method: "GET", callbackURL: NSURL(string: "cptwitterdemo://oauth"), scope: nil, success: { (credential: BDBOAuth1Credential!) -> Void in
      print("Got the request token")
      let authURL = NSURL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(credential.token)")
      UIApplication.sharedApplication().openURL(authURL!)
      
      }) { (error: NSError!) -> Void in
        print("Failed to get request token")
        self.loginCompletion?(user: nil, error: error)
    }
  }
  
  func openURL(url: NSURL) {
    fetchAccessTokenWithPath("oauth/access_token", method: "POST", requestToken: BDBOAuth1Credential(queryString: url.query), success: { (accessToken: BDBOAuth1Credential!) -> Void in
      print("Got the access token")
      TwitterClient.sharedInstance.requestSerializer.saveAccessToken(accessToken)
      
      TwitterClient.sharedInstance.GET("1.1/account/verify_credentials.json", parameters: nil, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
        // print("user: \(response)")
        let user = User(dictionary: response as! NSDictionary)
        User.currentUser = user
        print("user: \(user.name)")
        self.loginCompletion?(user: user, error: nil)
      }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
          print("error getting current user")
          self.loginCompletion?(user: nil, error: error)
      })
      
    }) { (error: NSError!) -> Void in
      print("Failed to receive access token")
      self.loginCompletion?(user: nil, error: error)
    }
  }
    

}
