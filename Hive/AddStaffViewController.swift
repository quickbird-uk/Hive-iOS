//
//  AddStaffViewController.swift
//  Hive
//
//  Created by Animesh. on 20/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class AddStaffViewController: UITableViewController, OptionsListDataSource
{
	//
	// MARK: - Properties & Outlets
	//
	
	let contacts = Contact.getAll("Fr")
	var selectedContact: Contact!
	var selectedRole: String!
	let accessToken = User.get()!.accessToken!
	var organisation: Organisation!
	
	@IBOutlet weak var contactCell: TableViewCellWithSelection!
	@IBOutlet weak var roleCell: TableViewCellWithSelection!
	
	func showError(message: String)
	{
		let alert = UIAlertController(
			title: "Oops!",
			message: message,
			preferredStyle: .ActionSheet)
		
		let addAction = UIAlertAction(title: "Add Contacts Now", style: .Default) {
			alert in
			if self.shouldPerformSegueWithIdentifier("addContact", sender: nil) {
				self.performSegueWithIdentifier("addContact", sender: nil)
			}
		}
		alert.addAction(addAction)
		
		let cancelAction = UIAlertAction(title: "I'll do it later.", style: .Cancel) {
			alert in
			self.navigationController?.popViewControllerAnimated(true)
		}

		alert.addAction(cancelAction)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	@IBAction func add(sender: UIBarButtonItem)
	{
		if contactCell.selectedOption == "Select"
		{
			let alert = UIAlertController(
				title: "Oops!",
				message: "Please select a contact before proceeding.",
				preferredStyle: .ActionSheet)
			let cancelAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
			alert.addAction(cancelAction)
			self.presentViewController(alert, animated: true, completion: nil)
			return
		}
		
		if roleCell.selectedOption == "Select"
		{
			let alert = UIAlertController(
				title: "Oops!",
				message: "Please assign a role before proceeding.",
				preferredStyle: .ActionSheet)
			let cancelAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
			alert.addAction(cancelAction)
			self.presentViewController(alert, animated: true, completion: nil)
			return
		}
		
		let staff = Staff.temporary()
		staff.personID = selectedContact.friendID
		print(organisation)
		staff.onOrganisationID = organisation.id
		staff.role = selectedRole
		HiveService.shared.addStaff(staff, accessToken: accessToken) {
			(didAdd, newStaff, error) -> Void in
			if didAdd && newStaff != nil {
				dispatch_async(dispatch_get_main_queue()) {
					newStaff!.moveToPersistentStore()
					self.navigationController?.popViewControllerAnimated(true)
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue()) {
					let errorMessage = error ?? "Something bad happened"
					let alert = UIAlertController(
						title: "Oops!",
						message: errorMessage,
						preferredStyle: .ActionSheet)
					let cancelAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
					alert.addAction(cancelAction)
					self.presentViewController(alert, animated: true, completion: nil)
				}
			}
		}
	}
	
	func updateCell(atIndex index: NSIndexPath, withOption option: String, selectedIndex: Int)
	{
		switch index.row
		{
			case 0:
				selectedContact = contacts![selectedIndex]
				contactCell.selectedOption = selectedContact.firstName! + " " + selectedContact.lastName!
			case 1:
				selectedRole = option
				roleCell.selectedOption = selectedRole
			default:
				break
		}
	}
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool
	{
		if identifier == "selectContactForStaff"
		{
			if contacts == nil {
				showError("You have no contacts yet. Please add one by tapping the + in the top bar in Contacts view. If you have already sent out invites you will have to wait until they are accepted.")
				return false
			}
			return true
		}
		
		return true
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "selectContactForStaff"
		{
			let destination = segue.destinationViewController as! OptionsListViewController
			destination.delegate = self
			var options = [String]()
			if contacts != nil {
				for contact in contacts!
				{
					options.append(contact.firstName! + " " + contact.lastName!)
				}
			}
			else {
				options.append("You have no contacts.")
				options.append("Please add a contact first.")
			}
			
			destination.options = options
			destination.senderCellIndexPath = tableView.indexPathForCell(contactCell)
		}
		
		if segue.identifier == "selectRoleForStaff"
		{
			let destination = segue.destinationViewController as! OptionsListViewController
			destination.delegate = self
			destination.options = Staff.Role.allRoles
			destination.senderCellIndexPath = tableView.indexPathForCell(roleCell)
		}
	}
}
