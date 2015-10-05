//
//  TweetsViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 9/30/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit
import CCInfiniteScrolling

class TweetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ComposeViewControllerDelegate {
  
  @IBOutlet weak var tableView: UITableView!
  
  var tweets: [Tweet]?
  private var refreshControl: UIRefreshControl!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Configure the UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 100
    tableView.addBottomInfiniteScrollingWithActionHandler() {
      self.fetchTweets(Int((self.tweets!.last!.idString)!))
    }
    
    fetchTweets()
    
    // Set up pull-to-refresh
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "onPullToRefresh:", forControlEvents: UIControlEvents.ValueChanged)
    tableView.insertSubview(refreshControl, atIndex: 0)
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("TweetCell") as! TweetCell
    cell.tweet = tweets![indexPath.row]

    // Set button handlers
    cell.retweetButton.tag = indexPath.row
    cell.retweetButton.addTarget(self, action: "onRetweet:", forControlEvents: .TouchUpInside)
    cell.favoriteButton.tag = indexPath.row
    cell.favoriteButton.addTarget(self, action: "onFavorite:", forControlEvents: .TouchUpInside)
    cell.replyButton.tag = indexPath.row
    cell.replyButton.addTarget(self, action: "onReply:", forControlEvents: .TouchUpInside)
    
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let tweets = tweets {
      return tweets.count
    } else {
      return 0
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func fetchTweets(oldestTweetId: Int? = nil, onCompletion: (() -> ())? = nil) {
    var params = [String:String]()
    if oldestTweetId != nil {
      let tweet = tweets![tweets!.count - 1]
      let maxId = Int(tweet.idString!)! - 1
      params["max_id"] = String(maxId)
    }
    TwitterClient.sharedInstance.homeTimelineWithParams(params) { (tweets, error) -> () in
      if error == nil {
        if oldestTweetId != nil {
          self.tweets?.appendContentsOf(tweets!)
        } else {
          self.tweets = tweets
        }
        dispatch_async(dispatch_get_main_queue()) {
          self.tableView.reloadData()
          onCompletion?()
        }
      }
    }
  }
  
  func reloadTweetForRow(row: Int) {
    dispatch_async(dispatch_get_main_queue()) {
      self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
    }
  }
  
  func onReply(sender: AnyObject) {
    let composeVC = storyboard?.instantiateViewControllerWithIdentifier(ComposeViewController.identifier) as! ComposeViewController
    composeVC.delegate = self
    composeVC.replyToTweet = tweets?[sender.tag]
    presentViewController(composeVC, animated: true, completion: nil)
  }
  
  func onRetweet(sender: AnyObject) {
    let row = sender.tag
    let tweet = tweets![row]

    if tweet.userHasRetweeted == true {
      // Unretweet
      TwitterClient.sharedInstance.unretweet(tweet) { (retweet, error) -> () in
        if error == nil {
          self.tweets![row].userHasRetweeted = false
          self.tweets![row].retweetCount = tweet.retweetCount! - 1
          self.reloadTweetForRow(row)
        }
      }
    } else {
      // Retweet
      TwitterClient.sharedInstance.retweet(tweet.idString!) { (updatedTweet, error) -> () in
        if error == nil {
          self.tweets![row] = updatedTweet!
          self.reloadTweetForRow(row)
        }
      }
    }
  }
  
  func onFavorite(sender: AnyObject) {
    let row = sender.tag
    let tweet = tweets![sender.tag]
    TwitterClient.sharedInstance.toggleFavorite(tweet.idString!, userHasFavorited: tweet.userHasFavorited!) { (updatedTweet, error) -> () in
      if error == nil {
        self.tweets![row] = updatedTweet!
        self.reloadTweetForRow(row)
      }
    }
  }
  
  func onPullToRefresh(sender: AnyObject) {
    self.fetchTweets() {
      self.refreshControl.endRefreshing()
    }
  }
  
  @IBAction func onLogout(sender: AnyObject) {
    User.currentUser?.logout()
  }
  
  func composeViewController(composeViewController: ComposeViewController, didTweet newTweet: Tweet) {
    tweets?.insert(newTweet, atIndex: 0)
    tableView.reloadData()
  }

  // MARK: - Navigation

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "composeNewTweet" {
      let vc = segue.destinationViewController as! ComposeViewController
      vc.delegate = self
    } else if segue.identifier == "viewTweetDetails" {
      let vc = segue.destinationViewController as! TweetDetailViewController
      let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
      vc.tweet = self.tweets![indexPath!.row]
    }
  }

}
