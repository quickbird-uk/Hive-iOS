//
//  VerifyPhoneViewController.swift
//  Hive
//
//  Created by Animesh. on 11/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import CoreData

class VerifyPhoneViewController: UIViewController, UITextFieldDelegate
{
    //
    // MARK: - Properties
    //
    
    var isUsingTempUser: Bool?
    var user: User?
    
    //
    // MARK: - Outlets
    //
    
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
	
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
    
    @IBAction func verify(sender: UIButton)
    {
		self.view.endEditing(true)
		guard let code = codeTextField.text else
		{
			showError("Code field can't be blank.")
			return
		}
		
        verifyButton.hidden = true
        activityIndicator.startAnimating()
        user!.passcode = code
    
    // Verify SMS code
        HiveService.shared.renewAccessTokenForUser(user!) {
            (didRenew, newToken, tokenExpiryDate, error) in
            guard didRenew else
			{
				dispatch_async(dispatch_get_main_queue()) {
					self.activityIndicator.stopAnimating()
					self.verifyButton.hidden = false
					self.showError(error!)
				}
				return
			}
			
        // Set verified flag to true and update access token
			
			if self.isUsingTempUser!
			{
				self.user!.isVerified = true
				self.user!.accessToken = newToken
				self.user!.accessExpiresOn = tokenExpiryDate
				self.user!.moveToPersistentStore()
			}
			
			else
			{
				self.user!.isVerified = true
				self.user!.accessToken = newToken
				self.user!.accessExpiresOn = tokenExpiryDate
			}
			
			Data.shared.saveContext(message: "User phone verified. Access token and expiry date updated.")
                
			dispatch_async(dispatch_get_main_queue()) {
				self.activityIndicator.stopAnimating()
				self.performSegueWithIdentifier("sync", sender: nil)
			}
        }
    }
    
    //
    // MARK: - View Controller
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if isUsingTempUser == false {
            user = User.get()
        }
        print("Verify Phone view loaded.")
        message.text = "We need to verify your phone number before you can proceed. Please enter the code sent to +44 \(user!.phone!)"
        
    // Send SMS code
		if isUsingTempUser! == false
		{
			HiveService.shared.sendSMSCodeToUser(user!) {
				(didSend, error) in
				guard didSend else
				{
					print("SMS could not be sent.")
                
					let alertController = UIAlertController(title: "Oops!", message: error!, preferredStyle: UIAlertControllerStyle.ActionSheet)
					let defaultAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: nil)
					alertController.addAction(defaultAction)
					dispatch_async(dispatch_get_main_queue()) {
						self.presentViewController(alertController, animated: true, completion: nil)
					}
					return
				}
				
				print("SMS sent successfully.")
			}
		}
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // FIXME: - handler memory warnings
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
    // Dismiss keyboard on tap
        self.view.endEditing(true)
    }
    
    //
    // MARK: - Text Field Delegate
    //
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        // TODO: - Call the verify() method from here
        return true
    }
}
