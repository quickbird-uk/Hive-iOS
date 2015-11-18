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
    //
    // MARK: - Properties & Outlets
    //
    
    var selectedCell: Int?
    var fetchedResultsController: NSFetchedResultsController!
    let user = User.get()!
    @IBOutlet var tasksTableView: UITableView!
    
    //
    // MARK: - Methods
    //
    
    func initFetchedResultsController()
    {
        let request = NSFetchRequest(entityName: Task.entityName)
        let dueDateSort = NSSortDescriptor(key: "dueDate", ascending: true)
        request.sortDescriptors = [dueDateSort]
        
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
    // MARK: - Fetched Results Controller Delegate
    //
    
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
    // MARK: - Table View Datasource
    //
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath)
    {
        let task = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Task
        cell.textLabel!.text = task.name ?? "A task with no name? Blasphemy!"
        cell.detailTextLabel!.text = task.state ?? "Undefined"
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        guard let sections = self.fetchedResultsController.sections else
        {
            return 0
        }
        
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sections = self.fetchedResultsController.sections!
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    //
    // MARK: - Table View Delegate
    //
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("TaskCell")
        self.configureCell(cell!, indexPath: indexPath)
        return cell!
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?
    {
        self.selectedCell = indexPath.row
        return indexPath
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        let task = fetchedResultsController.objectAtIndexPath(indexPath) as! Task
        if task.assignedByID == user.id {
            return true
        }
        else {
            return false
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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initFetchedResultsController()
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
        if segue.identifier == "showTaskDetails"
        {
            let taskCell = sender as! UITableViewCell
            
        }
        
    }
}
