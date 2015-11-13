//
//  AddTaskViewController.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class AddTaskViewController: UITableViewController, OptionsListDelegate
{
    //
    // MARK: - Properties
    //
    
    var selectedCellIndex: NSIndexPath!
    let user = User.get()
    let types = Task.getAllTypes()
    let fields = Field.getAll()
    var selectedFieldID: NSNumber?
    let contacts = Contact.getAll()
    var selectedContactID: NSNumber?
    
    //
    // MARK: - Outlets
    //
    
    @IBOutlet weak var nameCell: TableViewCellWithTextfield!
    @IBOutlet weak var typeCell: TableViewCellWithSelection!
    @IBOutlet weak var fieldCell: TableViewCellWithSelection!
    @IBOutlet weak var assignToPersonCell: TableViewCellWithSelection!
    @IBOutlet weak var notesCell: TableViewCellWithTextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet var addTaskForm: UITableView!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func add(sender: UIBarButtonItem)
    {
        let task                = Task.temporary()
        task.name               = nameCell.textField.text
        task.type               = typeCell.selection.text
        task.forField           = 1
        task.assignedTo         = selectedContactID
        task.dueDate            = datePicker.date
        task.taskDescription    = notesCell.textView.text
        task.assignedBy         = user!.id
        task.payRate            = 0
        
        HiveService.shared.addTask(accessToken: user!.accessToken!, newTask: task) {
            (added, error) in
            if added
            {
                task.moveToPersistentStore()
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()) {
                    self.showAlert(error!)
                }
            }
        }
    }
    
    @IBAction func cancel(sender: UIBarButtonItem)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //
    // MARK: - Methods
    //
    
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
    
    //
    // MARK: - Options List Delegate
    //
    
    func updateCell(atIndex index: NSIndexPath, withOption option: String, selectedIndex: Int)
    {
        switch index.row
        {
            // Type for task
            case 1:
                typeCell.selection.text = option
            
            // Field for task
            case 2:
                fieldCell.selection.text = option
                selectedFieldID = fields?[selectedIndex].id
            
            // Contact for task
            case 3:
                assignToPersonCell.selection.text = option
                selectedContactID = contacts?[selectedIndex].id
            
            default:    break
        }
        
        addTaskForm.reloadData()
    }
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
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
    
    //
    // MARK: - Navigation
    //
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "selectTypeForTask"
        {
            let destination = segue.destinationViewController as! OptionsListViewController
            destination.delegate = self
            destination.options = types
            destination.senderCellIndexPath = addTaskForm.indexPathForCell(typeCell)
        }
        
        if segue.identifier == "selectFieldForTask"
        {
            let destination = segue.destinationViewController as! OptionsListViewController
            destination.delegate = self
            var fieldNames = [String]()
            
        // Field names
            if fields != nil
            {
                for field in fields!
                {
                    fieldNames.append(field.name!)
                }
            }
            
            destination.options = fieldNames
            destination.senderCellIndexPath = addTaskForm.indexPathForCell(fieldCell)
        }
        
        if segue.identifier == "selectContactForTask"
        {
            let destination = segue.destinationViewController as! OptionsListViewController
            destination.delegate = self
            var contactNames = [String]()
            
        // Contact names
            if contacts != nil
            {
                for contact in contacts!
                {
                    contactNames.append("\(contact.firstName!) \(contact.lastName!)")
                }
            }
            
            destination.options = contactNames
            destination.senderCellIndexPath = addTaskForm.indexPathForCell(assignToPersonCell)
        }
    }
}















