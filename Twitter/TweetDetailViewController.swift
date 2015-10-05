//
//  TweetDetailViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 10/4/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit


class TweetDetailViewController: UIViewController, ComposeViewControllerDelegate {
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var handleLabel: UILabel!
  @IBOutlet weak var createdLabel: UILabel!
  @IBOutlet weak var tweetTextLabel: UILabel!
  @IBOutlet weak var replyButton: UIButton!
  @IBOutlet weak var retweetButton: UIButton!
  @IBOutlet weak var favoriteButton: UIButton!
  @IBOutlet weak var contextLabel: UILabel!
  @IBOutlet weak var contextImageView: UIImageView!
  @IBOutlet weak var contextLabelTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var nameLabelTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var profileImageViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var retweetsAndFavoritesLabel: UILabel!
  @IBOutlet weak var createdAtLabel: UILabel!
  @IBOutlet weak var actionBarTopLayoutConstraint: NSLayoutConstraint!

  var tweet: Tweet?
  
  private var displayTweet: Tweet? {
    didSet {
      tweetTextLabel.text = displayTweet?.text
      profileImageView.setImageWithURL(displayTweet?.user!.profileImageUrl!)
      profileImageView.layer.cornerRadius = 5
      profileImageView.clipsToBounds = true
      nameLabel.text = displayTweet?.user!.name
      handleLabel.text = "@\(displayTweet?.user!.screename as String!)"
      createdAtLabel.text = displayTweet?.createdAt?.formattedDateWithFormat("M/d/yy, h:mm a")
      
      let hasRetweets = displayTweet?.retweetCount > 0
      let hasFavorites = displayTweet?.favoriteCount > 0
      
      // Set up retweet and favorite counts
      if hasRetweets || hasFavorites  {
        retweetsAndFavoritesLabel.hidden = false
        actionBarTopLayoutConstraint.constant = 39
        var retweetsAndFavoritesString = ""
        if hasRetweets {
          retweetsAndFavoritesString += "\(String(displayTweet?.retweetCount as Int!)) RETWEETS  "
        }
        if hasFavorites {
          retweetsAndFavoritesString += "\(String(displayTweet?.favoriteCount as Int!)) FAVORITES"
        }
        retweetsAndFavoritesLabel.text = retweetsAndFavoritesString
      } else {
        actionBarTopLayoutConstraint.constant = -1
        retweetsAndFavoritesLabel.hidden = true
      }
      
      // Toggle context label
      if (tweet?.isReply == true) || (tweet?.isRetweet == true) {
        // Show context label
        contextLabel.hidden = false
        contextImageView.hidden = false
        nameLabelTopConstraint.constant = 27
        profileImageViewTopConstraint.constant = 30
      } else {
        // Hide context label
        contextLabel.hidden = true
        contextImageView.hidden = true
        nameLabelTopConstraint.constant = 8
        profileImageViewTopConstraint.constant = 11
      }
      
      // Set up context label text/images
      if tweet?.isReply == true {
        contextLabel.text = "in reply to @\(tweet?.replyToScreenName as String!)"
        contextImageView.image = UIImage(named: "reply.png")
      } else if tweet?.isRetweet == true {
        contextLabel.text = "\(tweet?.user!.name as String!) retweeted"
        contextImageView.image = UIImage(named: "retweet.png")
      }
      
      // Set up retweet button
      if tweet?.userHasRetweeted == true {
        retweetButton.setImage(UIImage(named: "retweeted.png"), forState: .Normal)
      } else {
        retweetButton.setImage(UIImage(named: "retweet.png"), forState: .Normal)
      }
      
      // Set up favorite button
      if tweet?.userHasFavorited == true {
        favoriteButton.setImage(UIImage(named: "favorited.png"), forState: .Normal)
      } else {
        favoriteButton.setImage(UIImage(named: "favorite.png"), forState: .Normal)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    displayTweet = tweet?.isRetweet == true ? tweet?.retweetSourceTweet : tweet
  }
  
  @IBAction func onReply(sender: AnyObject) {
    let composeVC = storyboard?.instantiateViewControllerWithIdentifier(ComposeViewController.identifier) as! ComposeViewController
    composeVC.delegate = self
    composeVC.replyToTweet = tweet
    presentViewController(composeVC, animated: true, completion: nil)
  }
  
  @IBAction func onRetweet(sender: AnyObject) {
    if tweet!.userHasRetweeted == true {
      // Unretweet
      TwitterClient.sharedInstance.unretweet(tweet!) { (retweet, error) -> () in
        if error == nil {
          self.displayTweet!.userHasRetweeted = false
          self.displayTweet!.retweetCount = self.tweet!.retweetCount! - 1
        }
      }
    } else {
      // Retweet
      TwitterClient.sharedInstance.retweet(tweet!.idString!) { (updatedTweet, error) -> () in
        if error == nil {
          self.tweet = updatedTweet!
          self.displayTweet = self.tweet
        }
      }
    }
  }

  @IBAction func onFavorite(sender: AnyObject) {
    TwitterClient.sharedInstance.toggleFavorite(tweet!.idString!, userHasFavorited: tweet!.userHasFavorited!) { (updatedTweet, error) -> () in
      if error == nil {
        self.tweet = updatedTweet!
        self.displayTweet = self.tweet
      }
    }
  }
  
  
}
