//
//  SignInViewController.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class SignInViewController: UITableViewController, UITextFieldDelegate
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
	@IBOutlet weak var registerButtonCell: TableViewCellWithButton!
	
	//
	// MARK: - Methods
	//
	
	func showError(message: String)
	{
		let alert = UIAlertController(
			title: "Oops!",
			message: message,
			preferredStyle: .ActionSheet)
		
		let cancelAction = UIAlertAction(title: "Try Again", style: .Cancel, handler: nil)
		alert.addAction(cancelAction)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}

    //
    // MARK: - Actions
    //
    
    @IBAction func passwordToggle(sender: UISwitch)
    {
        hidePasswordCell = !hidePasswordCell
        
        if hidePasswordCell {
			signInButtonCell.buttonTitle = "Request SMS Code"
		}
        else {
			signInButtonCell.buttonTitle = "Sign In"
        }
        
        layoutView.reloadData()
    }
    
    @IBAction func login(sender: UIButton)
    {
		if let phone = NSNumberFormatter().numberFromString(phoneCell.userResponse)
		{
			tempUser.phone = phone
		}
		else
		{
			showError("Please enter a phone number without spaces, international dial code (+44) or preceding 0.\nE.g. 7796604116")
			return
		}
		
		if lastNameCell.userResponse == ""
		{
			showError("Last name can't be blank.")
			return
		}
		
		if !hidePasswordCell && passwordCell.userResponse == ""
		{
			showError("Password can't be blank.")
			return
		}
		
        activityIndicator.startAnimating()
        signInButtonCell.buttonHidden = true
        
    // Login with phone and password
        if hidePasswordCell == false
        {
            tempUser.passcode = passwordCell.userResponse
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
								self.signInButtonCell.buttonTitle = "Let's start."
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
                        self.signInButtonCell.buttonHidden = false
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
            tempUser.lastName = lastNameCell.userResponse
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
						self.activityIndicator.stopAnimating()
						self.signInButtonCell.buttonHidden = false
                        self.presentViewController(alertController, animated: true, completion: nil)
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
	
	//
	// MARK: - View Controller Lifecycle
	//
	
    override func viewDidLoad()
    {
        super.viewDidLoad()
		
		UINavigationBar.appearance().titleTextAttributes = Design.shared.NavigationBarTitleStyle
		UIBarButtonItem.appearance().setTitleTextAttributes(Design.shared.NavigationBarButtonStyle, forState: UIControlState.Normal)
		
		phoneCell.textFieldDelegate = self
		lastNameCell.textFieldDelegate = self
		passwordCell.textFieldDelegate = self
    }
	
	override func viewWillAppear(animated: Bool)
	{
		navigationItem.title = "Sign In"
	}
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // FIXME: - Handle memory warning
    }

	//
	// MARK: - Text Field Delegate
	//
	
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		textField.resignFirstResponder()
		return true
	}
	
	func textFieldDidBeginEditing(textField: UITextField)
	{
		textField.returnKeyType = UIReturnKeyType.Done
	}
	
    //
    // MARK: - Navigation
    //
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
		navigationItem.title = ""
		activityIndicator.stopAnimating()
		signInButtonCell.buttonHidden = false
		
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
