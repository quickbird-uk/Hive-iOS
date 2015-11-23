//
//  AddFieldViewController.swift
//  Hive
//
//  Created by Animesh. on 21/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class AddFieldViewController: UITableViewController, OptionsListDataSource
{
	
	@IBOutlet weak var nameCell: TableViewCellWithTextfield!
	@IBOutlet weak var areaCell: TableViewCellWithTextfield!
	@IBOutlet weak var farmCell: TableViewCellWithSelection!
	@IBOutlet weak var locationCell: TableViewCellWithSelection!
	@IBOutlet weak var fieldDescriptionCell: TableViewCellWithTextView!
	@IBOutlet weak var doneBarButton: UIBarButtonItem!
	
	let userAccessToken = User.get()!.accessToken
	let farms = Organisation.getAll("owned")
	var selectedFarm: Organisation!
	var latitude: Double!
	var longitude: Double!
	
	@IBAction func done(sender: UIBarButtonItem)
	{
		let newField = Field.temporary()
		newField.name = nameCell.userResponse
		newField.areaInHectares = NSNumberFormatter().numberFromString(areaCell.userResponse)
		newField.onOrganisationID = selectedFarm.id
		newField.fieldDescription = fieldDescriptionCell.plainText
		newField.latitude = latitude
		newField.longitude = longitude
		
		HiveService.shared.addField(newField, accessToken: userAccessToken!) {
			(didAdd, newField, error) -> Void in
			
			guard didAdd && newField != nil else
			{
				self.showAlert(error!)
				return
			}
	
			newField!.moveToPersistentStore()
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	@IBAction func cancel(sender: UIBarButtonItem)
	{
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func showAlert(errorMessage: String)
	{
		let alert = UIAlertController(
			title: "Oops! We couldn't add the task.",
			message: errorMessage,
			preferredStyle: .ActionSheet)
		
		let cancelAction = UIAlertAction(title: "Try Again", style: .Cancel, handler: nil)
		alert.addAction(cancelAction)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	func updateCell(atIndex index: NSIndexPath, withOption option: String, selectedIndex: Int)
	{
		farmCell.selectedOption = option
		selectedFarm = farms![selectedIndex]
		tableView.reloadData()
	}
	
	func updateLocationCell(atIndex index: NSIndexPath, withOption option: String, selectedLatitude: Double, selectedLongitude: Double)
	{
		locationCell.selectedOption = option
		self.latitude = selectedLatitude
		self.longitude = selectedLongitude
		print("Field location = (\(self.latitude), \(self.longitude))")
		tableView.reloadData()
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

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "selectLocationForField"
		{
			let destination = segue.destinationViewController as! SpatialViewController
			destination.delegate = self
			destination.senderCellIndexPath = tableView.indexPathForCell(locationCell)
		}
		
		if segue.identifier == "selectFarmForField"
		{
			let destination = segue.destinationViewController as! OptionsListViewController
			destination.delegate = self
			destination.senderCellIndexPath = tableView.indexPathForCell(farmCell)
			
			var farmNames = [String]()
			
			if farms != nil
			{
				for farm in farms!
				{
					farmNames.append(farm.name!)
				}
			}
			destination.options = farmNames
		}
	}
}
