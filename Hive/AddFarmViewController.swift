//
//  AddFarmViewController.swift
//  Hive
//
//  Created by Animesh. on 20/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class AddFarmViewController: UITableViewController
{
	let user = User.get()!
	@IBOutlet weak var nameCell: TableViewCellWithTextfield!
	@IBOutlet weak var addressCell: TableViewCellWithTextView!
	@IBOutlet var formTableView: UITableView!
	
	@IBAction func cancel(sender: UIBarButtonItem)
	{
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func add(sender: UIBarButtonItem)
	{
		let farm					= Organisation.temporary()
		farm.name				= nameCell.userResponse
		farm.orgDescription		= addressCell.plainText
		
		HiveService.shared.addOrganisation(accessToken: user.accessToken!, organisation: farm) {
			(added, newOrg, error) -> Void in
			guard added, let newFarm = newOrg else
			{
				print("Something bad happened.")
				return
			}
			newFarm.moveToPersistentStore()
			
			dispatch_async(dispatch_get_main_queue()) {
				self.dismissViewControllerAnimated(true, completion: nil)
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
