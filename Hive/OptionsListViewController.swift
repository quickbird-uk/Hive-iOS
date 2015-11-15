//
//  OptionsListTableViewController.swift
//  Hive
//
//  Created by Animesh. on 02/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

protocol OptionsListDataSource
{
    func updateCell(atIndex index: NSIndexPath, withOption option: String, selectedIndex: Int)
}

class OptionsListViewController: UITableViewController
{
    //
    // MARK: - Properties
    //
    
    var delegate: OptionsListDataSource!
    var options: [String]!
    var senderCellIndexPath: NSIndexPath?
    var selectedIndex: Int = -1
    
    //
    // MARK: - Methods
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //
    // MARK: - Table View
    //

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return options.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("OptionCell", forIndexPath: indexPath)
        cell.textLabel!.text = options[indexPath.row]
        if indexPath.row == selectedIndex {
            cell.accessoryType = .Checkmark
        }
        else {
            cell.accessoryType = .None
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        selectedIndex = indexPath.row
        tableView.reloadData()
        delegate.updateCell(atIndex: senderCellIndexPath!, withOption: options[indexPath.row], selectedIndex: selectedIndex)
        self.navigationController?.popViewControllerAnimated(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
