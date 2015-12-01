//
//  JournalViewController.swift
//  Hive
//
//  Created by Animesh. on 23/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import CoreData

class JournalViewController: UITableViewController, NSFetchedResultsControllerDelegate
{
	//
	// MARK: - Outlets & Properties
	//
	
	var field: Field!
	var tasks: [Task]!
	var sortedTasks = [[Task](), [Task](), [Task]()]
	let secondsInAWeek: NSTimeInterval = 604800.0
	let secondsInAMonth: NSTimeInterval = 2628000.0
	
	@IBAction func done(sender: UIBarButtonItem)
	{
		self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
	}
	
	//
	// MARK: - Fetched Results Controller
	//
	
	var fetchedResultsController: NSFetchedResultsController!
	
	func initFetchedResultsController()
	{
		let request = NSFetchRequest(entityName: Task.entityName)
		request.predicate = NSPredicate(format: "forFieldID == %d AND state == %@", field.id!.integerValue, "Finished")
		let dateSort = NSSortDescriptor(key: "completedOnDate", ascending: false)
		request.sortDescriptors = [dateSort]
		
		self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Data.shared.permanentContext, sectionNameKeyPath: nil, cacheName: nil)
		self.fetchedResultsController.delegate = self
		do {
			try self.fetchedResultsController.performFetch()
			tasks = fetchedResultsController.fetchedObjects as! [Task]
			sortTasks()
		}
		catch {
			print("Fatal error. Failed to initialize fetched results controller \(error)")
		}
	}
	
	func sortTasks()
	{
		for task in tasks
		{
			let timeInterval = NSDate().timeIntervalSinceDate(task.completedOnDate!)
			print(timeInterval)
			if timeInterval <= secondsInAWeek {
				sortedTasks[0].append(task)
			}
			else if timeInterval > secondsInAWeek && timeInterval <= secondsInAMonth {
				sortedTasks[1].append(task)
			}
			else {
				sortedTasks[2].append(task)
			}
		}
	}
	
	func controllerWillChangeContent(controller: NSFetchedResultsController)
	{
		tableView.beginUpdates()
	}
	
	func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
	{
		switch type
		{
			case .Insert:
				tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
			case .Delete:
				tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
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
				break
			case .Delete:
				break
			case .Update:
				break
			case .Move:
				break
		}
	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController)
	{
		tableView.endUpdates()
	}
	
	//
	// MARK: - Table View
	//
	
	func configureCell(cell: UITableViewCell!, atIndexPath indexPath: NSIndexPath)
	{
		let task = sortedTasks[indexPath.section][indexPath.row]
		cell.textLabel?.text = task.type ?? "Some kind of task"
		cell.detailTextLabel?.text = Design.shared.stringFromDate(task.completedOnDate!)
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return sortedTasks.count
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		print("Sorted 0")
		print(sortedTasks[0].count)
		print("Sorted 1")
		print(sortedTasks[1].count)
		print("Sorted 2")
		print(sortedTasks[2].count)
		return sortedTasks[section].count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("journalCell")!
		configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
	{
		return false
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		switch section
		{
			case 0 :
				return "Last 7 days"
			case 1 :
				return "Last 30 days"
			case 2 :
				return "Earlier"
			default :
				return "Long time ago"
		}
	}
	
	//
	// MARK: - View Controller Lifecycle
	//
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		initFetchedResultsController()
		print("Journal for field with name \(field.name!)")
		print(sortedTasks.count)
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
        let destination = segue.destinationViewController as! JournalJobSheetViewController
		let senderCell = sender as! UITableViewCell
		let indexPath = tableView.indexPathForCell(senderCell)!
		let task = sortedTasks[indexPath.section][indexPath.row]
		destination.task = task
    }
}
