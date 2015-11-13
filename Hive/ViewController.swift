//
//  ViewController.swift
//  Hive
//
//  Created by Animesh. on 09/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController
{
    //
    // MARK: - Outlets
    //
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var expiryDateLabel: UILabel!
    @IBOutlet weak var offlineView: UIView!
    @IBOutlet weak var syncButton: UIBarButtonItem!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func signout(sender: UIBarButtonItem)
    {
        let alert = UIAlertController(title: "Are you sure?", message: "All data on this phone will be deleted and you will no longer receive notifications.", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let yesAction = UIAlertAction(title: "Yes", style: .Default) {
            alert in
            Data.shared.deleteAllData()
            self.performSegueWithIdentifier("authenticate", sender: nil)
        }
        alert.addAction(yesAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func sync(sender: UIBarButtonItem)
    {
        performSegueWithIdentifier("sync", sender: nil)
    }
    
    //
    // MARK: - View Controller
    //
    
    func checkNetworkConnection()
    {
        if !NetworkService.isConnected()
        {
            offlineView.hidden = false
            syncButton.enabled = false
        }
        else
        {
            offlineView.hidden = true
            syncButton.enabled = true
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
    // Set text style for navigation bar title
        
        let titleStyle = [
            NSFontAttributeName: UIFont(name: "AvenirNext-Medium", size: 18.0)!,
            NSForegroundColorAttributeName: UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        ]
        UINavigationBar.appearance().titleTextAttributes = titleStyle
        
    // Set text style for navigation bar button
        
        let barButtonAttributes = [
            NSFontAttributeName : UIFont(name: "Avenir Next", size: 17.0)!,
            NSForegroundColorAttributeName: UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        ]
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonAttributes, forState: UIControlState.Normal)
        
    // If there's a user signed in
        
        if let user = User.get()
        {
            if user.isVerified == true
            {
                if NetworkService.isConnected()
                {
                    performSegueWithIdentifier("sync", sender: nil)
                }
            }
            else
            {
                performSegueWithIdentifier("verifyPhone", sender: nil)
            }
        }
        
    // If no user signed in
            
        else
        {
            performSegueWithIdentifier("authenticate", sender: nil)
        }
    }
 
    override func viewWillAppear(animated: Bool)
    {
        if let user = User.get()
        {
            checkNetworkConnection()
            
            if user.lastName != nil
            {
                self.titleLabel.text = user.firstName! + " " + user.lastName!
            }
                
            self.phoneLabel.text! = "+44 \(user.phone!)"
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            self.expiryDateLabel.text! = "until " + dateFormatter.stringFromDate(user.accessExpiresOn!)
            if user.lastSync != nil {
                self.lastUpdatedLabel.text! = "Last updated " + dateFormatter.stringFromDate(user.lastSync!)
            }
            else {
                if NetworkService.isConnected() {
                    self.performSegueWithIdentifier("sync", sender: nil)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        // FIXME: - Handle memory warning
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

