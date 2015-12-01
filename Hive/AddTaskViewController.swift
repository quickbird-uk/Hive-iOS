//
//  AddTaskViewController.swift
//  Hive
//
//  Created by Animesh. on 04/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class AddTaskViewController: UITableViewController, OptionsListDataSource
{
    //
    // MARK: - Properties
    //
	
	let user = User.get()
    let types = Task.getAllTypes()
    let fields = Field.getAll()
    var selectedFieldID: NSNumber?
	var field: Field!
	var staffs: [Staff]!
    var selectedStaffID: NSNumber?
    
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
        let task						= Task.temporary()
        task.name					= nameCell.userResponse
        task.type					= typeCell.selectedOption
		task.state					= TaskState.Pending.rawValue
        task.forFieldID				= selectedFieldID
		task.assignedToID			= selectedStaffID
        task.dueDate					= datePicker.date
        task.taskDescription			= notesCell.plainText
        task.assignedByID			= user!.id
        task.payRate					= 66.6
		
        HiveService.shared.addTask(task, accessToken: user!.accessToken!) {
            (didAdd, newTask, error) in
            if didAdd && newTask != nil
            {
                newTask!.moveToPersistentStore()
				self.dismissViewControllerAnimated(true, completion: nil)
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
                typeCell.selectedOption = option
            
            // Field for task
            case 2:
                fieldCell.selectedOption = option
                selectedFieldID = fields?[selectedIndex].id
            
            // Contact for task
            case 3:
                assignToPersonCell.selectedOption = option
                selectedStaffID = staffs?[selectedIndex].personID
            
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
    }
	
	override func viewWillAppear(animated: Bool)
	{
		if selectedFieldID != nil {
			field = Field.getFieldWithID(selectedFieldID!)
			if field != nil {
				staffs = Staff.getAll("forOrganisation", orgID: field!.onOrganisationID!.integerValue)
			}
		}
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
            let destination = segue.destinationViewController as! TaskTypeViewController
            destination.delegate = self
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
				destination.options = fieldNames
            }
			else
			{
				destination.options = ["You have no fields.", "Please add a field first."]
				destination.allowSelection = false
			}
            
			
            destination.senderCellIndexPath = addTaskForm.indexPathForCell(fieldCell)
        }
        
        if segue.identifier == "selectContactForTask"
        {
            let destination = segue.destinationViewController as! OptionsListViewController
            destination.delegate = self
            var staffNames = [String]()
            
        // Contact names
            if staffs != nil
            {
                for staff in staffs!
                {
                    staffNames.append("\(staff.firstName!) \(staff.lastName!)")
                }
				destination.options = staffNames
            }
			else
			{
				if selectedFieldID != nil {
					destination.options = ["No staff added to this field.", "Please add staff using Farms menu", "and try again later."]
				}
				else {
					destination.options = ["Please select a field first."]
				}
				destination.allowSelection = false
			}
			
            destination.senderCellIndexPath = addTaskForm.indexPathForCell(assignToPersonCell)
        }
    }
}















