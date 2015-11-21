//
//  TaskTypeViewController.swift
//  Hive
//
//  Created by Animesh. on 21/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class TaskTypeViewController: UITableViewController
{
	var delegate: OptionsListDataSource!
	var senderCellIndexPath: NSIndexPath!
	var selectedIndex: Int = -1

    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		selectedIndex = indexPath.row
		let headerView: UITableViewHeaderFooterView = tableView.headerViewForSection(indexPath.section)!
		let headerTitle = headerView.textLabel!.text!.capitalizedString
		let selectedCell = tableView.cellForRowAtIndexPath(indexPath)!
		let option = headerTitle + " - " + selectedCell.textLabel!.text!
		tableView.reloadData()
		delegate.updateCell!(atIndex: senderCellIndexPath!, withOption: option, selectedIndex: selectedIndex)
		self.navigationController?.popViewControllerAnimated(true)
	}


    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
