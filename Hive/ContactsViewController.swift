//
//  ContactsViewController.swift
//  Hive
//
//  Created by Animesh. on 17/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import CoreData

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate
{
    //
    // MARK: - Properties
    //
    
    var selectedCell: Int?
    var fetchedResultsController: NSFetchedResultsController!
    
    //
    // MARK: - Methods
    //
    
    func initFetchedResultsController()
    {
        let request = NSFetchRequest(entityName: Contact.entityName)
        let firstNameSort = NSSortDescriptor(key: "firstName", ascending: true)
        request.sortDescriptors = [firstNameSort]
        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: Data.shared.permanentContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController.delegate = self
        do {
            try self.fetchedResultsController.performFetch()
            print(fetchedResultsController.fetchedObjects as! [Contact])
        }
        catch {
            print("Fatal error. Failed to initialize fetched results controller \(error)")
        }
    }
    
    func confirmDelete(contact: Contact)
    {
        let alert = UIAlertController(
            title: "Are you sure you want to remove \(contact.firstName!) from your contacts?",
            message: "The changes made here will not affect your phone address book.",
            preferredStyle: .ActionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) {
            alert in
            Data.shared.permanentContext.deleteObject(contact)
        }
        alert.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //
    // MARK: - Outlets
    //
    
    @IBOutlet weak var contactsTableView: UITableView!
    
    //
    // MARK: - Fetched Results Controller Delegate
    //
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        self.contactsTableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        switch type
        {
            case .Insert:
                self.contactsTableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.contactsTableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
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
                self.contactsTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                self.contactsTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(self.contactsTableView.cellForRowAtIndexPath(indexPath!) as! CustomTableViewCell, indexPath: indexPath!)
            case .Move:
                self.contactsTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                self.contactsTableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.contactsTableView.endUpdates()
    }
    
    //
    // MARK: - Table View Datasource
    //
    
    func configureCell(cell: CustomTableViewCell, indexPath: NSIndexPath)
    {
        let contact = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Contact
        cell.title = "\(contact.firstName ?? "Darth") \(contact.lastName ?? "Vader")"
        cell.subtitle = "\((contact.phone ?? "0123456789") ?? "1234567890")"
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
            let contactToDelete = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Contact
            self.confirmDelete(contactToDelete)
        }
    }
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.initFetchedResultsController()
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
    
    }
}
