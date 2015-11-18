//
//  FarmDetailsViewController.swift
//  Hive
//
//  Created by Animesh. on 17/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import CoreData

class FarmDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate
{
	//
	// MARK: - Properties & Outlets
	//
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var descriptionTextView: UITextView!
	@IBOutlet weak var roleLabel: UILabel!
	var farm: Organisation?
	var staffResultsController: NSFetchedResultsController!
	var staff: [Staff]?
	
	//
	// MARK: - Methods
	//
	
	func initFetchedResultsController()
	{
		let request = NSFetchRequest(entityName: Staff.entityName)
		request.predicate = NSPredicate(format: "organisation == %@", farm?.id ?? 0)
		let nameSort = NSSortDescriptor(key: "name", ascending: true)
		request.sortDescriptors = [nameSort]
		
		staffResultsController = NSFetchedResultsController(
			fetchRequest: request,
			managedObjectContext: Data.shared.permanentContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		staffResultsController.delegate = self
		do {
			try staffResultsController.performFetch()
			staff = staffResultsController.fetchedObjects as? [Staff]
			print("Number of staff fetched = \(staffResultsController.fetchedObjects?.count)")
		}
		catch {
			print("Fatal error. Failed to initialize fetched results controller \(error)")
		}
	}
	
	//
	// MARK: - Table View
	//
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if staff != nil {
			return staff!.count
		}
		else {
			return 1
		}
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("staffCell")
		
		if staff != nil {
			cell!.textLabel!.text = "Abc"
			cell!.detailTextLabel!.text = "Def"
			return cell!
		}
		else {
			cell!.textLabel!.text = "Nobody works here."
			cell!.detailTextLabel!.text = ""
			return cell!
		}
	}
	
	//
	// MARK: - View Controller Lifecycle
	//
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		nameLabel.text = farm?.name ?? "Unnamed Farm"
		descriptionTextView.text = farm?.orgDescription == "" ? "No description either. Wow!" : farm?.orgDescription
		roleLabel.text = farm?.role ?? "Undefined"
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
