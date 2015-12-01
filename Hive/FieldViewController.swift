//
//  FieldViewController.swift
//  Hive
//
//  Created by Animesh. on 06/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class FieldViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    //
    // MARK: - Outlets & Properties
    //
    
    var itemIndex: Int = 0
    var field: Field!
	var tasks: [Task]!
    let user = User.get()!
	
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var farmNameButton: UIButton!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var activityListView: UITableView!
	@IBOutlet weak var deleteButton: UIButton!
    
	@IBAction func deleteField(sender: UIButton)
	{
		
	}
    //
    // MARK: - Table View
    //
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if tasks != nil
		{
			return tasks.count
		}
		return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActivityCell")!
        cell.textLabel?.text = tasks[indexPath.row].type
		let completionDate = tasks[indexPath.row].completedOnDate
		if completionDate != nil {
			cell.detailTextLabel?.text = Design.shared.stringFromDate(completionDate!)
		}
		else {
			cell.detailTextLabel?.text = "Recently"
		}
        return cell
    }

    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
		nameLabel.text = field.name
		let farmID = field.onOrganisationID
		let farm = Organisation.getOrganisationWithID(farmID!)!
		let farmName = farm.name!
		farmNameButton.setTitle(farmName, forState: .Normal)
		areaLabel.text = "\(field.areaInHectares!) acres"
		descriptionLabel.text = field.fieldDescription!
		tasks = Task.getTasksForField(Int(field.id!), withState: "Finished")
		
		// Delete Button
		let staffs = Staff.getAll("forOrganisation", orgID: farmID!.integerValue)
		if staffs != nil {
			for staff in staffs! {
				print(staff.role)
				if staff.personID == user.id {
					if staff.role == "Owner" {
						deleteButton.hidden = false
					}
				}
			}
		}
    }
	
	override func viewWillAppear(animated: Bool)
	{
		
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
        if segue.identifier == "showFarmDetails"
		{
			let destination = segue.destinationViewController as! FarmDetailsViewController
			let farmID = field.onOrganisationID
			destination.farm = Organisation.getOrganisationWithID(farmID!)
		}
		
		if segue.identifier == "showFieldJournal"
		{
			let destinationNavController = segue.destinationViewController as! UINavigationController
			let destination = destinationNavController.viewControllers.first as! JournalViewController
			destination.field = field
		}
    }
}
