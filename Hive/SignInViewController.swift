//
//  SignInViewController.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class SignInViewController: UITableViewController
{
    //
    // MARK: - Properties
    //
    
    var tempUser = User.temporary()
    var hidePasswordCell = true

    //
    // MARK: - Outlets
    //
    
    @IBOutlet weak var phoneCell: TableViewCellWithTextfield!
    @IBOutlet weak var lastNameCell: TableViewCellWithTextfield!
    @IBOutlet weak var usePasswordSwitchCell: TableViewCellWithSwitch!
    @IBOutlet weak var passwordCell: TableViewCellWithTextfield!
    @IBOutlet weak var signInButtonCell: TableViewCellWithButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var layoutView: UITableView!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func passwordToggle(sender: UISwitch)
    {
        hidePasswordCell = !hidePasswordCell
        
        if hidePasswordCell {
            signInButtonCell.changeButtonTitleTo(newTitle: "Request SMS Code")
        }
        else {
            signInButtonCell.changeButtonTitleTo(newTitle: "Sign In")
        }
        
        layoutView.reloadData()
    }
    
    @IBAction func login(sender: UIButton)
    {
        activityIndicator.startAnimating()
        signInButtonCell.button.hidden = true
        let phone = NSNumberFormatter().numberFromString(phoneCell.textField.text!)!
        tempUser.phone = phone
        
    // Login with phone and password
        if hidePasswordCell == false
        {
            tempUser.passcode = passwordCell.textField.text
            HiveService.shared.renewAccessToken(tempUser) {
                (token, expiryDate, error) in
                if error == nil
                {
            // Login successful. Set access token & expiration
                    self.tempUser.accessToken = token
                    self.tempUser.accessExpiresOn = expiryDate
                    let user = self.tempUser.moveToPersistentStore()
                    
            // Update other user details
                    HiveService.shared.getAccountDetails(user!) {
                        (updatedUser, error) -> Void in
                        if error == nil && updatedUser != nil
                        {
                            user!.updatedWithDetailsFromUser(updatedUser!)
                            dispatch_async(dispatch_get_main_queue()) {
                                self.signInButtonCell.changeButtonTitleTo(newTitle: "Let's start.")
                                self.signInButtonCell.button.hidden = false
                                self.activityIndicator.stopAnimating()
                                
                                // Segue to verify phone number
                                self.performSegueWithIdentifier("verifyPhone", sender: nil)
                            }
                        }
                    }
                }
            
        // Login failed
                else
                {
                    print("Login failed. User not updated")
                    
            // Show a system alert
                    let alertController = UIAlertController(title: "Oops!", message: error!, preferredStyle: UIAlertControllerStyle.ActionSheet)
                    let defaultAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel) {
                        alert in
                        self.activityIndicator.stopAnimating()
                        self.signInButtonCell.button.hidden = false
                    }
                    alertController.addAction(defaultAction)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
        
    // Login with SMS code
        if hidePasswordCell
        {
            tempUser.lastName = lastNameCell.getText()
            HiveService.shared.requestSMSCode(tempUser) {
                (smsSent, error) in
                if smsSent == true
                {
        // SMS sent. Segue to phone verification
                    dispatch_async(dispatch_get_main_queue()) {
                        self.performSegueWithIdentifier("verifyPhone", sender: nil)
                    }
                }
                else
                {
        // Sending SMS failed
                    print("SMS could not be sent.")
                    
            // Show an action sheet displaying the error
                    let alertController = UIAlertController(title: "Oops!", message: error!, preferredStyle: UIAlertControllerStyle.ActionSheet)
                    
                    let defaultAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.presentViewController(alertController, animated: true, completion: nil)
                        self.signInButtonCell.button.hidden = false
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    //
    // MARK: - Table View Delegate
    //
    
   override  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if hidePasswordCell {
            self.passwordCell.alpha = 0.0
        }
        else {
            UIView.animateWithDuration(0.5) {
                self.passwordCell.alpha = 1.0
            }
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
    // Set text styles for navigation bar title
        
        let titleStyle = [
            NSFontAttributeName: UIFont(name: "AvenirNext-Medium", size: 18.0)!
        ]
        UINavigationBar.appearance().titleTextAttributes = titleStyle
        
    // Set text style for navigation bar button
        
        let barButtonAttributes = [
            NSFontAttributeName : UIFont(name: "Avenir Next", size: 17.0)!
        ]
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonAttributes, forState: UIControlState.Normal)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        // Dismiss keyboard when a tap is registered elsewhere in the view
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // FIXME: - Handle memory warning
    }

    //
    // MARK: - Navigation
    //
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "verifyPhone"
        {
            let destination = segue.destinationViewController as! VerifyPhoneViewController
            if !hidePasswordCell
            {
                destination.user = User.get()
                destination.isUsingTempUser = false
            }
            else
            {
                destination.user = tempUser
                destination.isUsingTempUser = true
            }
        }
    }
}
