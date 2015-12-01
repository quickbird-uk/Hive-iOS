//
//  TasksViewController.swift
//  Hive
//
//  Created by Animesh. on 06/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import CoreData

class TasksViewController: UITableViewController, NSFetchedResultsControllerDelegate
{
    @IBOutlet var tasksTableView: UITableView!
	@IBOutlet weak var addBarButton: UIBarButtonItem!
	
	var selectedIndexPath: NSIndexPath!
	let user = User.get()!
	var task: Task!
	var taskAssignedBy: String!
	var taskForField: Field!
	
    //
    // MARK: - Fetched Results Controller
    //
	
	var fetchedResultsController: NSFetchedResultsController!

	func initFetchedResultsController()
	{
		let request = NSFetchRequest(entityName: Task.entityName)
		let dueDateSort = NSSortDescriptor(key: "dueDate", ascending: true)
		request.sortDescriptors = [dueDateSort]
		request.predicate = NSPredicate(format: "state == %@", "Pending")
		
		self.fetchedResultsController = NSFetchedResultsController(
			fetchRequest: request,
			managedObjectContext: Data.shared.permanentContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		self.fetchedResultsController.delegate = self
		do {
			try self.fetchedResultsController.performFetch()
			print(fetchedResultsController.fetchedObjects as! [Task])
		}
		catch {
			print("Fatal error. Failed to initialize fetched results controller \(error)")
		}
	}
	
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        tasksTableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        switch type
        {
        case .Insert:
            tasksTableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tasksTableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
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
            tasksTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tasksTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            self.configureCell(tasksTableView.cellForRowAtIndexPath(indexPath!)!, indexPath: indexPath!)
        case .Move:
            tasksTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tasksTableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        tasksTableView.endUpdates()
    }
    
    //
    // MARK: - Table View
    //
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath)
    {
        let task = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Task
        cell.textLabel!.text = task.name ?? "A task with no name? Blasphemy!"
		let field = Field.getFieldWithID(task.forFieldID!)!
        cell.detailTextLabel!.text = field.name ?? "In a galaxy far far away"
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        guard let sections = self.fetchedResultsController.sections else {
            return 0
        }
		
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let sections = self.fetchedResultsController.sections else {
			return 0
		}
		
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("TaskCell")
        self.configureCell(cell!, indexPath: indexPath)
        return cell!
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?
    {
        self.selectedIndexPath = indexPath
        return indexPath
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
		return true
    }
	
	override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath)
	{
		guard online else
		{
			let alert = UIAlertController(title: "Offline Mode", message: "You can't make any changes to your tasks while offline.", preferredStyle: .ActionSheet)
			let okAction = UIAlertAction(title: "Got it!", style: .Default, handler: nil)
			alert.addAction(okAction)
			self.presentViewController(alert, animated: true, completion: nil)
			return
		}
		
		let task = fetchedResultsController.objectAtIndexPath(indexPath) as! Task
		if task.assignedByID != user.id
		{
			let alert = UIAlertController(title: "Not authorised", message: "You can delete only those tasks which you have assigned to others.", preferredStyle: .ActionSheet)
			let okAction = UIAlertAction(title: "Got it!", style: .Default, handler: nil)
			alert.addAction(okAction)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}
	
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete
        {
            let taskToDelete = fetchedResultsController.objectAtIndexPath(indexPath) as! Task
            self.confirmDelete(taskToDelete)
        }
    }
	
	func confirmDelete(task: Task)
	{
		let alert = UIAlertController(
			title: "Are you sure you want to remove \(task.name!) from your tasks?",
			message: "The changes made here will sync to all your staff.",
			preferredStyle: .ActionSheet)
		
		let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) {
			alert in
			Data.shared.permanentContext.deleteObject(task)
			Data.shared.saveContext(message: "Deleted task successfully.")
		}
		alert.addAction(deleteAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alert.addAction(cancelAction)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	//
	// MARK: - View Controller Lifecycle
	//
	
	var online: Bool {
		get {
			return NetworkService.isConnected()
		}
	}
	
	let offlineViewHeight: CGFloat = 30.0
	
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initFetchedResultsController()
	}
	
	override func viewWillAppear(animated: Bool)
	{
		if online {
			self.addBarButton.enabled = true
		}
		else {
			self.addBarButton.enabled = false
		}
	}

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

    //
    // MARK: - Navigation
    //
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "showTaskDetails"
        {
			let destination = segue.destinationViewController as! TaskDetailsViewController
			destination.task = fetchedResultsController.objectAtIndexPath(selectedIndexPath) as! Task
        }
		
		if segue.identifier == "recordTask"
		{
			let destination = segue.destinationViewController as! RecordTaskViewController
			destination.task = task
			destination.assignedBy = taskAssignedBy
			destination.onField = taskForField.name!
		}
    }
}
