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
		guard NetworkService.isConnected() else
		{
			self.showError("You need to be connected to the internet to synchronize data across devices.")
			return
		}
		
		performSegueWithIdentifier("sync", sender: nil)
    }
	
	//
	// MARK: - View Controller Lifecycle
	//
	
    override func viewDidLoad()
    {
        super.viewDidLoad()
        UINavigationBar.appearance().titleTextAttributes = Design.shared.NavigationBarTitleStyle
        UIBarButtonItem.appearance().setTitleTextAttributes(Design.shared.NavigationBarButtonStyle, forState: UIControlState.Normal)
    }
	
	override func viewDidAppear(animated: Bool)
	{
		// Check if a user is signed in
		// Then check if their phone number is verified
		// Then get on with it
		
		guard let user = User.get() else
		{
			self.navigationController?.performSegueWithIdentifier("authenticate", sender: nil)
			return
		}
		
		if user.isVerified == false
		{
			self.navigationController?.performSegueWithIdentifier("verifyPhone", sender: nil)
			return
		}
		
		self.titleLabel.text = "\(user.firstName ?? "Darth") \(user.lastName ?? "Vader")"
		self.phoneLabel.text! = "+44 \(user.phone ?? 0123456789)"
		self.lastUpdatedLabel.text! = "Last updated " + Design.shared.stringFromDate(user.lastSync)
		
		offlineView.hidden = NetworkService.isConnected()
		syncButton.enabled = NetworkService.isConnected()
	}
    
    override func didReceiveMemoryWarning()
    {
        // FIXME: - Handle memory warning
        super.didReceiveMemoryWarning()
    }
}

