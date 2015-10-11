//
//  ProfileViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 10/7/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit
import ImageEffects
import UIColor_Hex_Swift

class ProfileViewController: ContentViewController, UITableViewDelegate, UITableViewDataSource, TweetCellDelegate {
  
  // MARK: - Outlets

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var tableHeaderView: UIView!
  @IBOutlet weak var profileBackgroundImageView: UIImageView!
  @IBOutlet weak var profileBackgroundImageViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var profileImageViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var handleLabel: UILabel!
  @IBOutlet weak var tweetCountLabel: UILabel!
  @IBOutlet weak var followingCountLabel: UILabel!
  @IBOutlet weak var followersCountLabel: UILabel!
  
  // MARK: - Properties

  static let identifier = "ProfileViewController"
  
  var user: User!
  
  private var profileBackgroundImage: UIImage!
  private let profileImageViewHeight: CGFloat = 90.0
  private let numberFormatter = NSNumberFormatter()
  private var tweets: [Tweet]?
  private var hasLoadedOldestTweet = false
  
  // MARK: - Initializer

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.numberFormatter.numberStyle = .DecimalStyle
    
    if self.user == nil {
      self.user = User.currentUser
    }

    self.tableView.delegate = self
    self.tableView.dataSource = self
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 100
    tableView.addBottomInfiniteScrollingWithActionHandler() {
      if self.hasLoadedOldestTweet != true {
        self.fetchTweets(Int((self.tweets!.last!.idString)!))
      } else {
        self.tableView.infiniteScrollingDisabled = true
      }
    }
    
    profileBackgroundImageView.backgroundColor = UIColor.colorWithCSS("#\(self.user.profileColor as String!)")
    
    if let profileBannerImageUrl = user.profileBannerImageUrl {
      self.profileBackgroundImageView.hidden = false
      let request = NSURLRequest(URL: profileBannerImageUrl)
      self.profileBackgroundImageView.setImageWithURLRequest(request, placeholderImage: nil, success: { (request, response, image) -> Void in
        self.profileBackgroundImageView.image = image
        self.profileBackgroundImage = image
      }, failure: { (request, response, error) -> Void in
        print("Failed to get profile background image")
      })
    }
    
    self.profileImageView.setImageWithURL(user.profileImageUrl)
    self.profileImageView.layer.cornerRadius = 6.0
    self.profileImageView.layer.borderWidth = 4.0
    self.profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
    self.profileImageView.layer.masksToBounds = true
    
    self.numberFormatter.numberStyle = .DecimalStyle
    self.tweetCountLabel.text = self.numberFormatter.stringFromNumber(user.tweetCount!)
    self.followingCountLabel.text = self.numberFormatter.stringFromNumber(user.followingCount!)
    self.followersCountLabel.text = self.numberFormatter.stringFromNumber(user.followersCount!)
    self.nameLabel.text = user.name
    self.handleLabel.text = "@\(user.screename as String!)"

    self.fetchTweets()
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
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let offset = self.tableView.contentOffset.y
    if offset < 0 {
      self.profileImageViewHeightConstraint.constant = profileImageViewHeight + abs(offset)
      self.profileBackgroundImageViewTopConstraint.constant = offset
      if self.profileBackgroundImage != nil {
        self.profileBackgroundImageView.image = self.profileBackgroundImage.blurredImageWithRadius(offset * -0.25)
      }

    } else {
      self.profileImageViewHeightConstraint.constant = profileImageViewHeight
      self.profileBackgroundImageViewTopConstraint.constant = 0.0
      if self.profileBackgroundImage != nil {
        self.profileBackgroundImageView.image = self.profileBackgroundImage
      }
    }
  }
  
  // MARK: - Helpers
  
  func reloadTweetForRow(row: Int) {
    dispatch_async(dispatch_get_main_queue()) {
      self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
    }
  }
  
  // MARK: - Getters
  
  func fetchTweets(oldestTweetId: Int? = nil, onCompletion: (() -> ())? = nil) {
    var params = ["screen_name": user.screename!]
    if oldestTweetId != nil {
      let tweet = tweets![tweets!.count - 1]
      let maxId = Int(tweet.idString!)! - 1
      params["max_id"] = String(maxId)
    }
    TwitterClient.sharedInstance.userTimelineWithParams(params) { (tweets, error) -> () in
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
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "viewTweetDetails" {
      let vc = segue.destinationViewController as! TweetDetailViewController
      let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
      vc.tweet = self.tweets![indexPath!.row]
    }
  }
}
