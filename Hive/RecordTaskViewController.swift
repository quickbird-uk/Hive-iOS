//
//  RecordTaskViewController.swift
//  Hive
//
//  Created by Animesh. on 06/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit
import QuartzCore

let secondsPerMinute = 60.0
let minutesPerHour = 60.0
let secondsPerHour = secondsPerMinute * minutesPerHour
let hoursPerDay = 24.0

class RecordTaskViewController: UIViewController
{

    //
    // MARK: - Outlets & Properties
    //
    
    var displayLink: CADisplayLink!
    var lastDisplayLinkTimeStamp: CFTimeInterval!
	var secondsTaken: Int!
	var minutesTaken: Int!
	var hoursTaken: Int!
	var task: Task!
	var assignedBy: String!
	var onField: String!
	
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var taskDescriptionLabel: UITextView!
    @IBOutlet weak var timerDisplay: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var startPauseButton: UIButton!
    
    //
    // MARK: - Actions & Methods
    //
    
    @IBAction func reset(sender: UIButton)
    {
		resetTimer()
    }
	
	func resetTimer()
	{
		// Pause display link updates
		displayLink.paused = true;
		
		// Set default numeric display value
		timerDisplay.text = "00:00:00"
		lastDisplayLinkTimeStamp = 0.0
		
		startPauseButton.setTitle("Start", forState: .Normal)
	}
	
    @IBAction func pause(sender: UIButton)
    {
		pauseTimer()
    }
	
	func pauseTimer()
	{
		displayLink.paused = !displayLink.paused
		if displayLink.paused {
			startPauseButton.setTitle("Resume", forState: .Normal)
		}
		else {
			startPauseButton.setTitle("Pause", forState: .Normal)
		}
	}
	
    @IBAction func finish(sender: UILongPressGestureRecognizer)
    {
		if sender.state == UIGestureRecognizerState.Began
		{
			timerDisplay.alpha = 0.6
			pauseTimer()
			confirmFinish()
		}
    }
    
    @IBAction func cancel(sender: UIBarButtonItem)
    {
		resetTimer()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func confirmFinish()
    {
        let alertController = UIAlertController(title: "Are you sure you want to mark task complete?", message: "You won't be able to resume or change task details later.", preferredStyle: .ActionSheet)
        
        let yesAction = UIAlertAction(title: "Yes", style: .Default) {
            alertAction in
            self.performSegueWithIdentifier("showJobSheet", sender: nil)
        }
        alertController.addAction(yesAction)
        
		let noAction = UIAlertAction(title: "Cancel", style: .Cancel) {
			alertAction in
			self.timerDisplay.alpha = 1.0
		}
        alertController.addAction(noAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func displayLinkUpdate(sender: CADisplayLink)
    {
        // Update running tally
        lastDisplayLinkTimeStamp = lastDisplayLinkTimeStamp + displayLink.duration
		print(lastDisplayLinkTimeStamp)
		
		if lastDisplayLinkTimeStamp <= 60 {
			secondsTaken = Int(lastDisplayLinkTimeStamp)
			minutesTaken = 0
			hoursTaken = 0
		}
		else {
			secondsTaken = Int(lastDisplayLinkTimeStamp % secondsPerMinute)
			minutesTaken = Int(lastDisplayLinkTimeStamp/secondsPerMinute)
			hoursTaken = Int(lastDisplayLinkTimeStamp/secondsPerHour)
		}
		
        // Format the running tally to display on the last two significant digits
        let formattedString = String(format: "%02u:%02u:%02u", hoursTaken, minutesTaken, secondsTaken)
        
        // Display the formatted running tally //
        timerDisplay.text = formattedString
        
    }
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        timerDisplay.text = "00:00:00"
		taskDescriptionLabel.text = task.taskDescription ?? "Task has no detailed description."
        
        // Initializing the display link and directing it to call our displayLinkUpdate: method when an update is available
        displayLink = CADisplayLink(target: self, selector: "displayLinkUpdate:")
        
        // Ensure that the display link is initially not updating
        displayLink.paused = false
        
        // Scheduling the Display Link to Send Notifications
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        // Initial timestamp
        lastDisplayLinkTimeStamp = displayLink.timestamp
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
		let destination = segue.destinationViewController as! JobSheetViewController
		task.completedOnDate = NSDate()
		task.timeTaken = lastDisplayLinkTimeStamp
		destination.task = task
		destination.secondsTaken = secondsTaken
		destination.minutesTaken = minutesTaken
		destination.hoursTaken = hoursTaken
		destination.assignedBy = assignedBy
		destination.onField = onField
		resetTimer()
	}
}
 