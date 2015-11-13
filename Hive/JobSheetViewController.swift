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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
