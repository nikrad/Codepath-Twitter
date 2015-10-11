//
//  TweetsViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 9/30/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit
import CCInfiniteScrolling

class TweetsViewController: ContentViewController, UITableViewDelegate, UITableViewDataSource, TweetCellDelegate, ComposeViewControllerDelegate {
  
  // MARK: - Outlets
  
  @IBOutlet weak var tableView: UITableView!
  
  // MARK: - Properties
  
  private var tweets: [Tweet]?
  private var refreshControl: UIRefreshControl!
  
  // MARK: - Initializer
  
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
    
    self.fetchTweets()
    
    // Set up pull-to-refresh
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "onPullToRefresh:", forControlEvents: UIControlEvents.ValueChanged)
    tableView.insertSubview(refreshControl, atIndex: 0)
  }
  
  // MARK: - UITableViewDataSource
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(TweetCell.identifier) as! TweetCell
    cell.tweet = tweets![indexPath.row]
    cell.delegate = self
    return cell
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let tweets = tweets {
      return tweets.count
    } else {
      return 0
    }
  }
  
  // MARK: - UITableViewDelegate
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  // MARK: - Getters

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
  
  // MARK: - Action handlers
  
  func onReply(sender: AnyObject) {
    let composeVC = storyboard?.instantiateViewControllerWithIdentifier(ComposeViewController.identifier) as! ComposeViewController
    composeVC.delegate = self
    composeVC.replyToTweet = tweets?[sender.tag]
    presentViewController(composeVC, animated: true, completion: nil)
  }
  
  func onPullToRefresh(sender: AnyObject) {
    self.fetchTweets() {
      self.refreshControl.endRefreshing()
    }
  }
  
  // MARK: - TweetCellDelegate
  
  func tweetCell(tweetCell: TweetCell, didTapProfileImageView imageView: UIImageView) {
    let tweet = tweets?[(tableView.indexPathForCell(tweetCell)?.row)!] as Tweet!
    let vc = storyboard?.instantiateViewControllerWithIdentifier(ProfileViewController.identifier) as! ProfileViewController
    vc.user = tweet.isRetweet == true ? tweet.retweetSourceTweet!.user : tweet.user
    navigationController?.pushViewController(vc, animated: true)
  }
  
  func tweetCell(tweetCell: TweetCell, didTapReplyButton replyButton: UIButton) {
    let vc = storyboard?.instantiateViewControllerWithIdentifier(ComposeViewController.identifier) as! ComposeViewController
    vc.replyToTweet = tweets?[(tableView.indexPathForCell(tweetCell)?.row)!]
    presentViewController(vc, animated: true, completion: nil)
  }
  
  func tweetCell(tweetCell: TweetCell, didTapReweetButton retweetButton: UIButton) {
    let row = tableView.indexPathForCell(tweetCell)!.row
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
  
  func tweetCell(tweetCell: TweetCell, didTapFavoriteButton favoriteButton: UIButton) {
    let row = tableView.indexPathForCell(tweetCell)!.row
    let tweet = tweets![row]
    TwitterClient.sharedInstance.toggleFavorite(tweet.idString!, userHasFavorited: tweet.userHasFavorited!) { (updatedTweet, error) -> () in
      if error == nil {
        self.tweets![row] = updatedTweet!
        self.reloadTweetForRow(row)
      }
    }
  }
  
  // MARK: - ComposeViewControllerDelegate
  
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
