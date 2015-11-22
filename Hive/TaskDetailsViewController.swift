//
//  TaskDetailsViewController.swift
//  Hive
//
//  Created by Animesh. on 05/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import MapKit

class TaskDetailsViewController: UIViewController, MKMapViewDelegate
{
    //
    // MARK: - Outlets & Properties
    //
    
    var task: Task!
	let user = User.get()!
	lazy var geocoder = CLGeocoder()
	var latitude: Double!
	var longitude: Double!
	var pin: CustomPin!
	
	var taskAssignedBy: String!
	var taskAssignedTo: String!
	var taskForField: Field!
	
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskAssignedByButton: UIButton!
    @IBOutlet weak var taskStatusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
	@IBOutlet weak var taskDescriptionView: UITextView!
    
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
		if task != nil
		{
			taskNameLabel.text = task.name!
			
			if task.assignedByID == user.id
			{
				taskAssignedBy = user.firstName! + " " + user.lastName!
				taskAssignedByButton.setTitle("By " + taskAssignedBy, forState: .Normal)
				taskAssignedByButton.userInteractionEnabled = false
			}
			else
			{
				var assignedByContact = Contact.getContactWithID(task.assignedByID!)
				if assignedByContact == nil {
					assignedByContact = Contact.temporary()
					assignedByContact!.firstName = "Unknown"
					assignedByContact!.lastName = "Person"
				}
				taskAssignedBy = assignedByContact!.firstName! + " " + assignedByContact!.lastName!
 				taskAssignedByButton.setTitle("By " + taskAssignedBy, forState: .Normal)
			}
			
			taskDescriptionView.text = task.taskDescription!
			taskStatusLabel.text = task.state
			if task.dueDate != nil
			{
				dueDateLabel.text = Design.shared.stringFromDate(task.dueDate!)
			}
			else
			{
				dueDateLabel.text = "Not assigned"
			}
			
			mapView.delegate = self
			mapView.mapType = MKMapType.HybridFlyover
			taskForField = Field.getFieldWithID(task.forFieldID!)
			self.latitude = Double(taskForField!.latitude!)
			self.longitude = Double(taskForField!.longitude!)
			let fieldCoordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
			let coordinateRegion = MKCoordinateRegionMakeWithDistance(fieldCoordinate,
				2000 * 2.0, 2000 * 2.0)
			mapView.setRegion(coordinateRegion, animated: true)
			self.pin = CustomPin(coordinate: fieldCoordinate, title: "Locating...", subtitle: "")
			print(pin.title)
			self.mapView.addAnnotation(pin)
			self.mapView.selectAnnotation(self.pin, animated: true)
		}
    }

	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
	{
		let annotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
		annotation.pinTintColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0)
		annotation.canShowCallout = true
		annotation.animatesDrop = true
		
		// Reverse geocode location
		geocoder.reverseGeocodeLocation(CLLocation(latitude: self.latitude, longitude: self.longitude)) {
			(placemarks, error) -> Void in
			if placemarks != nil
			{
				self.pin.title		= placemarks!.first!.locality ?? "Somewhere in the country..."
				self.pin.subtitle	= placemarks!.first!.postalCode ?? " "
			}
		}
		return annotation
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
		if segue.identifier == "recordTask"
		{
			let destinationNavController = segue.destinationViewController as! UINavigationController
			let destination = destinationNavController.viewControllers.first as! RecordTaskViewController
			destination.task = task
			destination.navigationBar.title = task.name
			destination.assignedBy = taskAssignedBy
			destination.onField = taskForField.name!
		}
	}

}
