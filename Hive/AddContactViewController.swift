//
//  AddContactViewController.swift
//  Hive
//
//  Created by Animesh. on 19/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import Contacts

class AddContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    // 
    // MARK: - Properties
    //
    
    var contactStore = CNContactStore()
    var phoneNumbers = [NSNumber]()
    var contacts: [Contact]?
	let user = User.get()
	var selectedContact: Contact!
	
    //
    // MARK: - Outlets
    //
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchResultsTable: UITableView!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func cancel(sender: UIBarButtonItem)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func done(sender: UIBarButtonItem)
    {
		HiveService.shared.addContact(accessToken: user!.accessToken!, contactID: selectedContact.id!.integerValue) {
			(requestSent, error) -> Void in
			if error == nil
			{
				let alertController = UIAlertController(title: "Invite sent", message: "We have sent your invitation to \(self.selectedContact.firstName!) on their phone number +44 \(self.selectedContact.phone!). They will be notified on their phone and will appear in your Contacts if they accept your request.", preferredStyle: .ActionSheet)
				let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) {
					alert -> Void in
					self.dismissViewControllerAnimated(true, completion: nil)
				}
				alertController.addAction(okAction)
				
				HiveService.shared.downsync(self.user!) {
					error -> Void in
					print("Downsync complete after sending connection request.")
				}
				
				dispatch_async(dispatch_get_main_queue()) {
					self.presentViewController(alertController, animated: true, completion: nil)
				}
			}
			else
			{
				let alertController = UIAlertController(title: "Oops!", message: error!, preferredStyle: .ActionSheet)
				let tryAgainAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: nil)
				alertController.addAction(tryAgainAction)
				
				dispatch_async(dispatch_get_main_queue()) {
					self.presentViewController(alertController, animated: true, completion: nil)
				}
			}
		}
    }
    
    //
    // MARK: - Contacts Framework
    //
    
    func checkForContactsAccess(completionHandler: (accessGranted: Bool) -> Void)
    {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        
        switch authorizationStatus
        {
            case .Authorized:
                completionHandler(accessGranted: true)
            case .Denied, .NotDetermined:
                self.contactStore.requestAccessForEntityType(CNEntityType.Contacts) {
                    (access, accessError) in
                    if access
                    {
                        completionHandler(accessGranted: access)
                    }
                    else
                    {
                        if authorizationStatus == CNAuthorizationStatus.Denied
                        {
                            dispatch_async(dispatch_get_main_queue()) {
                                let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                                self.showMessage(message)
                            }
                        }
                    }
                }
            default:
                completionHandler(accessGranted: false)
        }
    }
    
    func fetchPhoneNumbers()
    {
        let keysToFetch = [CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        do {
            try self.contactStore.enumerateContactsWithFetchRequest(request) {
                (contact, stop) in
                for phone in contact.phoneNumbers
                {
            // Extract phone number strings from each contact object
                    let phoneObject = phone.value as! CNPhoneNumber
                    var phoneString = self.removeSpecialCharsFromString(phoneObject.stringValue)
                    
            // Remove country code
                    if phoneString.characters.count == 12
                    {
                        // Drop the first two characters
                        phoneString = String(phoneString.characters.dropFirst())
                        phoneString = String(phoneString.characters.dropFirst())
                    }
            
            // Convert phone string into a number and add it to phone array
                    let phoneNumber = NSNumberFormatter().numberFromString(phoneString)
                    if phoneNumber != nil {
                        self.phoneNumbers.append(phoneNumber!)
                    }
                }
            }
        }
        catch
        {
            print("Something bad happened while fetching contact book.")
        }
    }
    
    func showMessage(message: String)
    {
        let alertController = UIAlertController(title: "Hive", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alertController.addAction(dismissAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func removeSpecialCharsFromString(text: String) -> String
    {
        let allowedChars : Set<Character> = Set("0123456789".characters)
        return String(text.characters.filter {
            (char) in
            allowedChars.contains(char)
        })
        // This has very bad performance, because contains on an array is O(n)
    }
    
    //
    // MARK: - Table View 
    //
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.contacts != nil {
            return self.contacts!.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.textLabel!.text = self.contacts![indexPath.row].firstName! + " " + self.contacts![indexPath.row].lastName!
        cell.detailTextLabel!.text = "\(self.contacts![indexPath.row].phone!)"
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.accessoryType == .None
        {
            cell.accessoryType = .Checkmark
        }
		
		selectedContact = contacts![indexPath.row]
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.accessoryType == .Checkmark
        {
            cell.accessoryType = .None
        }
    }
    
    // 
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.searchResultsTable.backgroundColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        self.checkForContactsAccess {
            (accessGranted) in
            if accessGranted
            {
                self.fetchPhoneNumbers()
                print(self.phoneNumbers)
                
        // Make Hive API call
                HiveService.shared.findContacts(accessToken: self.user!.accessToken!, phoneNumbers: self.phoneNumbers) {
                    (contacts, error) in
                    if error == nil
                    {
                        self.contacts = contacts
                        dispatch_async(dispatch_get_main_queue()) {
                            self.activityIndicator.stopAnimating()
                            self.searchResultsTable.alpha = 1.0
                            self.searchResultsTable.reloadData()
                        }
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) 
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
