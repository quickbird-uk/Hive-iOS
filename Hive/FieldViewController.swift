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
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var farmNameButton: UIButton!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var activityListView: UITableView!
    
    //
    // MARK: - Table View
    //
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActivityCell")!
        cell.textLabel?.text = "Activity \(indexPath.row)"
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
		let farmName = Organisation.getOrganisationWithID(farmID!)!.name!
		farmNameButton.setTitle(farmName, forState: .Normal)
		areaLabel.text = "\(field.area!) acres"
		descriptionLabel.text = field.fieldDescription!
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
    }
}
