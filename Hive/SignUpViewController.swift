//
//  SignUpViewController.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class SignUpViewController: UITableViewController
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

    @IBOutlet weak var signupCell: TableViewCellWithButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func signup(sender: UIButton)
    {
        signupCell.button.alpha = 0.0
        activityIndicator.startAnimating()
        
    // Create a temporary user variable
        tempUser.firstName = firstNameCell.getText()
        tempUser.lastName = lastNameCell.getText()
        tempUser.phone = NSNumberFormatter().numberFromString(phoneCell.getText())!
        tempUser.passcode = passwordCell.getText()
        
    // Send a registration request
        HiveService.shared.signup(tempUser) {
            (user, error) in
            if error == nil && user != nil
            {
                // Registration successful. Update local database.
                user!.moveToPersistentStore()
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                    
                    // Segue to phone verification
                    self.performSegueWithIdentifier("verifyPhone", sender: nil)
                }
            }
    // Registration failed
            else
            {
                print(error)
                
                // Show an error action sheet
                let alertController = UIAlertController(title: "Oops!", message: error!, preferredStyle: UIAlertControllerStyle.ActionSheet)
                
                let defaultAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: nil)
                alertController.addAction(defaultAction)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.signupCell.button.alpha = 1
                    self.activityIndicator.stopAnimating()
                    self.presentViewController(alertController, animated: true, completion: nil)
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
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // FIXME: - Handler memory warnings
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        // Dismiss keyboard on tap
        self.view.endEditing(true)
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
        if segue.identifier == "verifyPhone"
        {
            let destination = segue.destinationViewController as! VerifyPhoneViewController
            destination.user = User.get()
            destination.isUsingTempUser = false
        }
    }
}
