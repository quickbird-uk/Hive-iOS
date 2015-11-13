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
    // MARK: - Actions
    //
    
    @IBAction func verify(sender: UIButton)
    {
        self.view.endEditing(true)
        verifyButton.hidden = true
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        user!.passcode = codeTextField.text
    
    // Verify SMS code
        HiveService.shared.renewAccessToken(user!) {
            (token, expiryDate, error) in
            if error == nil
            {
        // Set verified flag to true and update access token
                if self.isUsingTempUser!
                {
                    self.user!.isVerified = true
                    self.user!.accessToken = token
                    self.user!.accessExpiresOn = expiryDate
                    self.user!.moveToPersistentStore()
                }
                else
                {
                    self.user!.isVerified = true
                    self.user!.accessToken = token
                    self.user!.accessExpiresOn = expiryDate
                }
                Data.shared.saveContext(message: "User phone verified. Access token and expiry date updated.")
                
        // Segue to Sync
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.activityIndicator.stopAnimating()
                    self.performSegueWithIdentifier("sync", sender: nil)
                }
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
        self.activityIndicator.hidden = true
        message.text = "We need to verify your phone number before you can proceed. Please enter the code sent to +44 \(user!.phone!)"
        
    // Send SMS code
        HiveService.shared.requestSMSCode(user!) {
            (smsSent, error) in
            if smsSent == false
            {
        // SMS sending failed.
                print("SMS could not be sent.")
                
        // Show an error action sheet
                let alertController = UIAlertController(title: "Oops!", message: error!, preferredStyle: UIAlertControllerStyle.ActionSheet)
                let defaultAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: nil)
                alertController.addAction(defaultAction)
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
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
