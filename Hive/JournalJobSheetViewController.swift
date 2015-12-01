//
//  JournalJobSheetViewController.swift
//  Hive
//
//  Created by Animesh. on 23/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class JournalJobSheetViewController: UITableViewController
{
	var task: Task!
	let user = User.get()!
	var taskAssignedBy: String!
	var taskDoneBy: String!
	var field: String!
	@IBOutlet weak var taskNameCell: UITableViewCell!
	@IBOutlet weak var taskTypeCell: UITableViewCell!
	@IBOutlet weak var taskAssignedByCell: UITableViewCell!
	@IBOutlet weak var taskDoneByCell: UITableViewCell!
	@IBOutlet weak var taskOnFieldCell: UITableViewCell!
	@IBOutlet weak var timeSpentCell: UITableViewCell!
	@IBOutlet weak var dateCompletedCell: UITableViewCell!
	@IBOutlet weak var commentsCell: TableViewCellWithTextView!
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
	
		// Assigned By
		if task.assignedByID == user.id {
			taskAssignedBy = user.firstName! + " " + user.lastName!
		}
		else
		{
			var assignedByContact = Contact.getContactWithID(task.assignedByID!)
			if assignedByContact == nil
			{
				assignedByContact = Contact.temporary()
				assignedByContact!.firstName = "Unknown"
				assignedByContact!.lastName = "Person"
			}
			taskAssignedBy = assignedByContact!.firstName! + " " + assignedByContact!.lastName!
			taskAssignedByCell.detailTextLabel?.text = taskAssignedBy
		}
		
		// Done By
		if task.assignedToID == user.id {
			taskDoneBy = user.firstName! + " " + user.lastName!
		}
		else
		{
			var doneByContact = Contact.getContactWithID(task.assignedToID!)
			if doneByContact == nil
			{
				doneByContact = Contact.temporary()
				doneByContact!.firstName = "Unknown"
				doneByContact!.lastName = "Person"
			}
			taskDoneBy = doneByContact!.firstName! + " " + doneByContact!.lastName!
			taskDoneByCell.detailTextLabel?.text = taskDoneBy
		}
		
		// Field
		taskOnFieldCell.detailTextLabel?.text = Field.getFieldWithID(task.forFieldID!)?.name
		
		// Time Spent
		let timeInterval = task.timeTaken!.doubleValue
		let secondsTaken = Int(timeInterval % secondsPerMinute)
		let minutesTaken = Int(timeInterval / secondsPerMinute)
		let hoursTaken = Int(timeInterval / secondsPerHour)
		timeSpentCell.detailTextLabel?.text = "\(hoursTaken)h \(minutesTaken)m \(secondsTaken)s"
		
		// Task Details
		taskNameCell.detailTextLabel?.text = task.name
		taskTypeCell.detailTextLabel?.text = task.type
		dateCompletedCell.detailTextLabel?.text = Design.shared.stringFromDate(task.completedOnDate!)
		commentsCell.plainText = task.taskDescription ?? ""
	}

    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
    }

}
