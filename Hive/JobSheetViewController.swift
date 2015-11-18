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
	
    @IBOutlet var jobSheetView: UITableView!
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var taskTypeCell: UITableViewCell!
    @IBOutlet weak var assignedByCell: UITableViewCell!
    @IBOutlet weak var doneByCell: UITableViewCell!
    @IBOutlet weak var fieldNameCell: UITableViewCell!
    @IBOutlet weak var areaCoveredCell: UITableViewCell!
    @IBOutlet weak var timeSpentCell: UITableViewCell!
    @IBOutlet weak var dateCell: UITableViewCell!
    @IBOutlet weak var commentsCell: TableViewCellWithTextView!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func save(sender: UIBarButtonItem)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
		timeSpentCell.detailTextLabel!.text = "\(hoursTaken):\(minutesTaken):\(secondsTaken)"
		nameCell.detailTextLabel!.text = "\(task.name!)"
		taskTypeCell.detailTextLabel!.text = "\(task.type!)"
		assignedByCell.detailTextLabel!.text = "\(task.assignedByID!)"
		doneByCell.detailTextLabel!.text = "\(task.completedOnDate)"
		fieldNameCell.detailTextLabel!.text = "\(task.forFieldID!)"
		dateCell.detailTextLabel!.text = "\(task.completedOnDate!)"
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
