//
//  TaskDetailsViewController.swift
//  Hive
//
//  Created by Animesh. on 05/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import MapKit

class TaskDetailsViewController: UIViewController
{
    //
    // MARK: - Outlets & Properties
    //
    
    var task: Task!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskAssignedByButton: UIButton!
    @IBOutlet weak var taskStatusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var payRateLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    //
    // MARK: - Actions
    //
    
    @IBAction func start(sender: UIButton)
    {
        
    }
    
    @IBAction func deleteTask(sender: UIBarButtonItem)
    {
        
    }

    //
    // MARK: - View Controller Lifecycle
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
