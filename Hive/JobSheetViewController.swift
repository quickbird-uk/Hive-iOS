//
//  JobSheetViewController.swift
//  Hive
//
//  Created by Animesh. on 06/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class JobSheetViewController: UITableViewController
{
    //
    // MARK: - Outlets & Properties
    //
    
    var task: Task!
	var secondsTaken: Int!
	var minutesTaken: Int!
	var hoursTaken: Int!
	var assignedBy: String!
	var onField: String!
	var areaCovered: Double!
	let user = User.get()!
	
    @IBOutlet var jobSheetView: UITableView!
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var taskTypeCell: UITableViewCell!
    @IBOutlet weak var assignedByCell: UITableViewCell!
    @IBOutlet weak var doneByCell: UITableViewCell!
    @IBOutlet weak var fieldNameCell: UITableViewCell!
    @IBOutlet weak var timeSpentCell: UITableViewCell!
    @IBOutlet weak var dateCell: UITableViewCell!
    @IBOutlet weak var commentsCell: TableViewCellWithTextView!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func save(sender: UIBarButtonItem)
    {
		task.state = "Finished"
		task.completedOnDate = NSDate()
		task.taskDescription! += "\n\nComments from \(user.firstName!) \(user.lastName!):\n" + commentsCell.plainText
		HiveService.shared.updateTask(task, accessToken: user.accessToken!) {
			(didUpdate, updatedTask, error) -> Void in
			if didUpdate && updatedTask != nil {
				updatedTask!.moveToPersistentStore()
			}
			else {
				print(error)
			}
		}
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
		timeSpentCell.detailTextLabel!.text		= "\(hoursTaken)h \(minutesTaken)m \(secondsTaken)s"
		nameCell.detailTextLabel!.text			= task.name!
		taskTypeCell.detailTextLabel!.text		= task.type!
		assignedByCell.detailTextLabel!.text		= assignedBy
		let doneBy								= user.firstName! + " " + user.lastName!
		doneByCell.detailTextLabel!.text			= doneBy
		fieldNameCell.detailTextLabel!.text		= onField
		dateCell.detailTextLabel!.text			= Design.shared.stringFromDate(task.completedOnDate!)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	//
	// MARK: - Table View Delegate
	//
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		switch section
		{
			case 0:
				return "A copy will be sent to " + assignedBy
			case 1:
				return "Comments"
			default:
				return ""
		}
	}
}
