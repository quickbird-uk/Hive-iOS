//
//  FarmsViewController.swift
//  Hive
//
//  Created by Animesh. on 17/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import CoreData

class FarmsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate
{
    //
    // MARK: - Properties & Outlets
    //
    
    var selectedCell: Int?
	let user = User.get()!
    var fetchedResultsController: NSFetchedResultsController!
    @IBOutlet weak var farmsTable: UITableView!
    
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
	
    func initFetchedResultsController()
    {
        let request = NSFetchRequest(entityName: Organisation.entityName)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [nameSort]
        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: Data.shared.permanentContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController.delegate = self
        do {
            try self.fetchedResultsController.performFetch()
        }
        catch {
            print("Fatal error. Failed to initialize fetched results controller \(error)")
        }
    }
    
    func confirmDelete(org: Organisation)
    {
        let alert = UIAlertController(
            title: "Are you sure you want to remove \(org.name!) from your Farms?",
            message: "All fields and tasks on this farm alongwith the farm itself will be deleted from all your devices.",
            preferredStyle: .ActionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) {
            alert in
			HiveService.shared.deleteOrganisationWithID(org.id!.integerValue, accessToken: self.user.accessToken!) {
				(didDelete, error) in
				if didDelete && error == nil {
					dispatch_async(dispatch_get_main_queue()) {
						Data.shared.permanentContext.deleteObject(org)
					}
				}
				else {
					dispatch_async(dispatch_get_main_queue()) {
						self.showError("Something bad happened. Please try again.")
					}
				}
			}
        }
        alert.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
		
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //
    // MARK: - Fetched Results Controller Delegate
    //
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        self.farmsTable.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        switch type
        {
        case .Insert:
            self.farmsTable.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.farmsTable.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Move:
            break
        case .Update:
            break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type
        {
        case .Insert:
            self.farmsTable.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            self.farmsTable.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            self.configureCell(self.farmsTable.cellForRowAtIndexPath(indexPath!) as! CustomTableViewCell, indexPath: indexPath!)
        case .Move:
            self.farmsTable.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.farmsTable.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.farmsTable.endUpdates()
    }
    
    //
    // MARK: - Table View Datasource
    //
    
    func configureCell(cell: CustomTableViewCell, indexPath: NSIndexPath)
    {
        let farm = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Organisation
		cell.title = farm.name ?? "Farm has no name. Weird."
		cell.subtitle = farm.role ?? ""
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        guard let sections = self.fetchedResultsController.sections else
        {
            return 0
        }
        
        return sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sections = self.fetchedResultsController.sections!
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    //
    // MARK: - Table View Delegate
    //
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("CustomCell") as! CustomTableViewCell
        self.configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?
    {
        self.selectedCell = indexPath.row
        return indexPath
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete
        {
            let orgToDelete = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Organisation
            self.confirmDelete(orgToDelete)
        }
    }
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.initFetchedResultsController()
		UINavigationBar.appearance().titleTextAttributes = Design.shared.NavigationBarTitleStyle
		UIBarButtonItem.appearance().setTitleTextAttributes(Design.shared.NavigationBarButtonStyle, forState: UIControlState.Normal)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	//
	// MARK: - Navigation
	//
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "showFarmDetails"
		{
			let destination = segue.destinationViewController as! FarmDetailsViewController
			let senderCell = sender as! CustomTableViewCell
			let senderIndex = farmsTable.indexPathForCell(senderCell)
			destination.farm = fetchedResultsController.objectAtIndexPath(senderIndex!) as? Organisation
		}
	}
}
