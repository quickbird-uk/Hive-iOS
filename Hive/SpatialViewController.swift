//
//  LocationViewController.swift
//  Hive
//
//  Created by Animesh. on 21/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class CustomPin: NSObject, MKAnnotation
{
	@objc var coordinate: CLLocationCoordinate2D
	var title: String?
	var subtitle: String?
	
	init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String)
	{
		self.coordinate = coordinate
		self.title = title
		self.subtitle = subtitle
	}
}

class SpatialViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var doneBarButton: UIBarButtonItem!
	
	lazy var locationManager: CLLocationManager = {
		let manager = CLLocationManager()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyBest
		return manager
	}()
	
	lazy var geocoder = CLGeocoder()
	
	let regionRadius: CLLocationDistance = 5000
	var pin: CustomPin!
	var latitude: Double!
	var longitude: Double!
	var delegate: OptionsListDataSource!
	var senderCellIndexPath: NSIndexPath!
	
	@IBAction func done(sender: UIBarButtonItem)
	{
		delegate.updateLocationCell!(atIndex: senderCellIndexPath, withOption: self.pin.title!, selectedLatitude: latitude, selectedLongitude: longitude)
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	@IBAction func handleLongPressGesture(sender: UILongPressGestureRecognizer)
	{
		if sender.state == UIGestureRecognizerState.Began
		{
			if self.pin != nil {
				mapView.removeAnnotation(self.pin)
			}
		
			// Get CGPoint for the touch
			let pointOnScreen = sender.locationInView(mapView)
		
			// Convert it to latitude and longitude to show on a map
			let locationCoordinates = mapView.convertPoint(pointOnScreen, toCoordinateFromView: mapView)
		
			// Create the annotation and add it to the map
			self.pin = CustomPin(coordinate: locationCoordinates, title: "Locating...", subtitle: "")
			print(pin.title)
			self.mapView.addAnnotation(pin)
			self.mapView.selectAnnotation(self.pin, animated: true)
			self.latitude = self.pin.coordinate.latitude
			self.longitude = self.pin.coordinate.longitude
		}
	}
	
	//
	// MARK: - Location Manager Delegate
	//
	
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
	{
		if case .AuthorizedWhenInUse = status {
			manager.requestLocation()
		}
	}
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
	{
		print("Success")
		let region = MKCoordinateRegionMakeWithDistance(locations[0].coordinate, 800, 800);
		mapView.setRegion(region, animated: true)
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
	{
		print(error)
	}
	
	//
	// MARK: - Map View Delegate
	//
	
	func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
	{
		let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
		mapView.setRegion(region, animated: true)
	}
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
	{
		let annotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
		annotation.pinTintColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0)
		annotation.canShowCallout = true
		annotation.animatesDrop = true
		
		// Reverse geocode location
		geocoder.reverseGeocodeLocation(CLLocation(latitude: self.pin.coordinate.latitude, longitude: self.pin.coordinate.longitude)) {
			(placemarks, error) -> Void in
			if placemarks != nil
			{
				self.pin.title		= placemarks!.first!.locality ?? "Somewhere in the country..."
				self.pin.subtitle	= placemarks!.first!.postalCode ?? " "
				self.doneBarButton.enabled = true
			}
		}
		return annotation
	}


	override func viewDidLoad()
	{
        super.viewDidLoad()
		locationManager.requestWhenInUseAuthorization()
		doneBarButton.enabled = false
		mapView.delegate = self
		mapView.mapType = MKMapType.HybridFlyover
	}
	
	func centerMapOnLocation(location: CLLocation)
	{
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
			regionRadius * 2.0, regionRadius * 2.0)
		mapView.setRegion(coordinateRegion, animated: true)
	}
	
	
	

    override func didReceiveMemoryWarning() {
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
