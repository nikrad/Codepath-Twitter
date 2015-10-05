//
//  ComposeViewController.swift
//  Twitter
//
//  Created by Nikrad Mahdi on 10/4/15.
//  Copyright © 2015 Nikrad. All rights reserved.
//

import UIKit

@objc protocol ComposeViewControllerDelegate {
  optional func composeViewController(composeViewController: ComposeViewController, didTweet newTweet: Tweet)
}

class ComposeViewController: UIViewController, UITextViewDelegate {
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var handleLabel: UILabel!
  @IBOutlet weak var replyToLabel: UILabel!
  @IBOutlet weak var replyToImageView: UIImageView!
  @IBOutlet weak var nameLabelTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var profileImageViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var tweetTextView: UITextView!
  @IBOutlet weak var tweetButton: UIBarButtonItem!
  @IBOutlet weak var characterCountLabel: UILabel!
  
  static let identifier = "ComposeViewController"
  weak var delegate: ComposeViewControllerDelegate?
  var replyToTweet: Tweet?
  
  private var user: User? {
    didSet {
      profileImageView.setImageWithURL(user?.profileImageUrl!)
      nameLabel.text = user?.name
      handleLabel.text = "@\(user!.screename!)"
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tweetTextView.delegate = self

    user = User.currentUser
    
    profileImageView.layer.cornerRadius = 5
    profileImageView.clipsToBounds = true
    
    if replyToTweet != nil {
      replyToLabel.hidden = false
      replyToLabel.text = "In reply to \(replyToTweet?.user?.name as String!)"
      tweetTextView.text = "@\(replyToTweet?.user?.screename as String!) "
      replyToImageView.hidden = false
      nameLabelTopConstraint.constant = 27
      profileImageViewTopConstraint.constant = 30
      tweetButton.enabled = true
    } else {
      replyToLabel.hidden = true
      replyToImageView.hidden = true
      nameLabelTopConstraint.constant = 8
      profileImageViewTopConstraint.constant = 11
    }
    updateCharacterCountLabel(tweetTextView)

    tweetTextView.becomeFirstResponder()
  }
  
  func updateCharacterCountLabel(textView: UITextView) {
    let characterCount = textView.text.characters.count
    let remainingCharacters = 140 - characterCount
    characterCountLabel.text = String(remainingCharacters)
    if remainingCharacters < 0 {
      characterCountLabel.textColor = UIColor.redColor()
    } else {
      characterCountLabel.textColor = UIColor.lightGrayColor()
    }
  }
  
  func textViewDidChange(textView: UITextView) {
    updateCharacterCountLabel(textView)
    let characterCount = textView.text.characters.count
    tweetButton.enabled = characterCount > 0 && characterCount <= 140 ? true : false
  }
  
  @IBAction func onTweet(sender: AnyObject) {
    TwitterClient.sharedInstance.tweet(tweetTextView.text, inReplyToTweetIdString: replyToTweet?.idString) { (tweet, error) -> () in
      if error == nil {
        print(tweet)
        self.dismissViewControllerAnimated(true, completion: nil)
        self.delegate?.composeViewController?(self, didTweet: tweet!)
      }
    }
  }
  
  @IBAction func onCancel(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      // Get the new view controller using segue.destinationViewController.
      // Pass the selected object to the new view controller.
  }
  */

}
