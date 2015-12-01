//
//  SignUpViewController.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class SignUpViewController: UITableViewController, UITextFieldDelegate, LegalDataSource
{
    //
    // MARK: - Properties
    //
    
    var activeField: UITextField!
    var tempUser = User.temporary()
    
    //
    // MARK: - Outlets
    //
    
    @IBOutlet weak var firstNameCell: TableViewCellWithTextfield!
    @IBOutlet weak var lastNameCell: TableViewCellWithTextfield!
    @IBOutlet weak var phoneCell: TableViewCellWithTextfield!
    @IBOutlet weak var passwordCell: TableViewCellWithTextfield!
	@IBOutlet weak var privacyPolicyCell: TableViewCellWithButton!
	@IBOutlet weak var termsOfServiceCell: TableViewCellWithButton!
    @IBOutlet weak var signupCell: TableViewCellWithButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
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
    
    @IBAction func signup(sender: UIButton)
    {
		guard NetworkService.isConnected() else
		{
			showError("We can't connect to the internet at the moment. Please try again later.")
			return
		}
		
		if firstNameCell.userResponse == "" {
			showError("First name can't be blank.")
			return
		}
		
		if lastNameCell.userResponse == "" {
			showError("Last name can't be blank.")
			return
		}
		
		guard let phone = NSNumberFormatter().numberFromString(phoneCell.userResponse) else
		{
			showError("Phone number can't be blank.")
			return
		}
		
		if passwordCell.userResponse == "" {
			showError("Password must be 8 or more characters long.")
			return
		}
		
        signupCell.buttonHidden = true
        activityIndicator.startAnimating()
        
    // Create a temporary user variable
        tempUser.firstName = firstNameCell.userResponse
        tempUser.lastName = lastNameCell.userResponse
		tempUser.phone = phone
        tempUser.passcode = passwordCell.userResponse
        
    // Send a registration request
        HiveService.shared.signupUser(tempUser) {
            (didSignup, newUser, error) in
			
			guard didSignup && newUser != nil else
			{
				let alertController = UIAlertController(title: "Oops!", message: error!, preferredStyle: UIAlertControllerStyle.ActionSheet)
				
				let defaultAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: nil)
				alertController.addAction(defaultAction)
				
				dispatch_async(dispatch_get_main_queue()) {
					self.signupCell.buttonHidden = false
					self.activityIndicator.stopAnimating()
					self.presentViewController(alertController, animated: true, completion: nil)
				}
				return
			}

		// Registration successful. Update local database.
			newUser!.moveToPersistentStore()
			dispatch_async(dispatch_get_main_queue()) {
				self.activityIndicator.stopAnimating()
				self.performSegueWithIdentifier("verifyPhone", sender: nil)
			}
        }
    }

	//
	// MARK: - Legal Data Source
	//
	
	func userDidAcceptAgreement(atIndexPath index: NSIndexPath)
	{
		let cell = tableView.cellForRowAtIndexPath(index) as! TableViewCellWithButton
		cell.accessoryType = UITableViewCellAccessoryType.Checkmark
		cell.buttonTouchEnabled = false
		cell.reloadInputViews()
	}
	
	func userDidDeclineAgreement(atIndexPath index: NSIndexPath)
	{
		let cell = tableView.cellForRowAtIndexPath(index) as! TableViewCellWithButton
		cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		cell.reloadInputViews()
	}
	
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
		firstNameCell.textFieldDelegate = self
		lastNameCell.textFieldDelegate = self
		phoneCell.textFieldDelegate = self
		passwordCell.textFieldDelegate = self
    }
	
	override func viewWillAppear(animated: Bool)
	{
		navigationItem.title = "Sign up for Hive"
		guard termsOfServiceCell.accessoryType == .Checkmark && privacyPolicyCell.accessoryType == .Checkmark else
		{
			signupCell.buttonFaded = true
			signupCell.buttonTouchEnabled = false
			return
		}
		
		if NetworkService.isConnected() {
			self.navigationController?.navigationBar.barTintColor = Design.shared.lightBlueColor
		}
		else {
			self.navigationController?.navigationBar.barTintColor = Design.shared.redColor
		}
		
		signupCell.buttonFaded = false
		signupCell.buttonTouchEnabled = true
	}
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // FIXME: - Handler memory warnings
    }
	
    //
    // MARK: - Text Field Delegate
    //
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
        activeField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField)
    {
        activeField = nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        if textField.returnKeyType == UIReturnKeyType.Done
        {
            textField.resignFirstResponder()
        }
        else
        {
            self.view.viewWithTag(textField.tag+1)?.becomeFirstResponder()
        }
        return true
    }
    
    //
    // MARK: - Navigation
    //
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
		navigationItem.title = ""
		
        if segue.identifier == "verifyPhone"
        {
            let destination = segue.destinationViewController as! VerifyPhoneViewController
            destination.user = User.get()
            destination.isUsingTempUser = false
        }
		
		if segue.identifier == "showTOS" || segue.identifier == "accessoryTOS"
		{
			let destination = segue.destinationViewController as! LegalViewController
			destination.delegate = self
			destination.senderIndexPath = tableView.indexPathForCell(termsOfServiceCell)
			destination.documentName = "TOS"
			destination.navigationItem.title = "Terms of Service"
		}
		
		if segue.identifier == "showPrivacyPolicy" || segue.identifier == "accessoryPrivacy"
		{
			let destination = segue.destinationViewController as! LegalViewController
			destination.delegate = self
			destination.senderIndexPath = tableView.indexPathForCell(privacyPolicyCell)
			destination.documentName = "PrivacyPolicy"
			destination.navigationItem.title = "Privacy Policy"

		}
    }
}
