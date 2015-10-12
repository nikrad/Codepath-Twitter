//
//  TweetCell.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 9/30/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit
import AFNetworking
import DateTools

@objc protocol TweetCellDelegate {
  optional func tweetCell(tweetCell: TweetCell, didTapReplyButton replyButton: UIButton)
  optional func tweetCell(tweetCell: TweetCell, didTapReweetButton retweetButton: UIButton)
  optional func tweetCell(tweetCell: TweetCell, didTapFavoriteButton favoriteButton: UIButton)
  optional func tweetCell(tweetCell: TweetCell, didTapProfileImageView imageView: UIImageView)
}

class TweetCell: UITableViewCell {
  
  static let identifier = "TweetCell"
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var handleLabel: UILabel!
  @IBOutlet weak var createdLabel: UILabel!
  @IBOutlet weak var tweetTextLabel: UILabel!
  @IBOutlet weak var replyButton: UIButton!
  @IBOutlet weak var retweetCountLabel: UILabel!
  @IBOutlet weak var retweetButton: UIButton!
  @IBOutlet weak var favoriteCountLabel: UILabel!
  @IBOutlet weak var favoriteButton: UIButton!
  @IBOutlet weak var contextLabel: UILabel!
  @IBOutlet weak var contextImageView: UIImageView!
  @IBOutlet weak var contextLabelTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var nameLabelTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var profileImageViewTopConstraint: NSLayoutConstraint!

  weak var delegate: TweetCellDelegate?
  var displayTweet: Tweet? {
    didSet {
      createdLabel.text = displayTweet?.createdAt?.shortTimeAgoSinceNow()
      tweetTextLabel.text = displayTweet?.text
      profileImageView.image = nil
      profileImageView.setImageWithURL(displayTweet?.user!.profileImageUrl!)
      nameLabel.text = displayTweet?.user!.name
      handleLabel.text = "@\(displayTweet?.user!.screename as String!)"
      retweetCountLabel.text = displayTweet?.retweetCount > 0 ? "\(displayTweet?.retweetCount as Int!)" : ""
      favoriteCountLabel.text = displayTweet?.favoriteCount > 0 ? "\(displayTweet?.favoriteCount as Int!)" : ""
    }
  }
  var tweet: Tweet? {
    didSet {
      // Determine which tweet content to display
      displayTweet = tweet?.isRetweet == true ? tweet?.retweetSourceTweet : tweet
      
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
        retweetCountLabel.textColor = UIColor(red: 119/255, green: 178/255, blue: 85/255, alpha: 1)
      } else {
        retweetButton.setImage(UIImage(named: "retweet.png"), forState: .Normal)
        retweetCountLabel.textColor = UIColor.lightGrayColor()
      }

      // Set up favorite button
      if tweet?.userHasFavorited == true {
        favoriteButton.setImage(UIImage(named: "favorited.png"), forState: .Normal)
        favoriteCountLabel.textColor = UIColor(red: 255/255, green: 172/255, blue: 51/255, alpha: 1)
      } else {
        favoriteButton.setImage(UIImage(named: "favorite.png"), forState: .Normal)
        favoriteCountLabel.textColor = UIColor.lightGrayColor()
      }
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    accessoryType = .None
    profileImageView.layer.cornerRadius = 5
    profileImageView.clipsToBounds = true
    layoutMargins = UIEdgeInsetsZero

    self.replyButton.addTarget(self, action: "onTapReply:", forControlEvents: .TouchUpInside)
    self.retweetButton.addTarget(self, action: "onTapRetweet:", forControlEvents: .TouchUpInside)
    self.favoriteButton.addTarget(self, action: "onTapFavorite:", forControlEvents: .TouchUpInside)
    self.profileImageView.userInteractionEnabled = true
    let tap = UITapGestureRecognizer(target: self, action: "onTapProfileImageView:")
    self.profileImageView.addGestureRecognizer(tap)
  }
  
  func onTapProfileImageView(sender: UITapGestureRecognizer) {
    delegate?.tweetCell?(self, didTapProfileImageView: self.profileImageView)
  }

  func onTapReply(sender: UIButton) {
    delegate?.tweetCell?(self, didTapReplyButton: sender)
  }
  
  func onTapRetweet(sender: UIButton) {
    delegate?.tweetCell?(self, didTapReweetButton: sender)
  }
  
  func onTapFavorite(sender: UIButton) {
    delegate?.tweetCell?(self, didTapFavoriteButton: sender)
  }
}
