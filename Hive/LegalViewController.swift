//
//  LegalViewController.swift
//  Hive
//
//  Created by Animesh. on 15/11/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

protocol LegalDataSource
{
	func userDidAcceptAgreement(atIndexPath index: NSIndexPath)
	func userDidDeclineAgreement(atIndexPath index: NSIndexPath)
}

class LegalViewController: UIViewController
{
	//
	// MARK: - Properties & Outlets
	//
	
	var delegate: LegalDataSource!
	var senderIndexPath: NSIndexPath!
	var documentName: String!
	@IBOutlet weak var textView: UITextView!
	
	//
	// MARK: - Actions
	//
	
	@IBAction func accept(sender: UIBarButtonItem)
	{
		delegate.userDidAcceptAgreement(atIndexPath: senderIndexPath)
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func decline(sender: UIBarButtonItem)
	{
		delegate.userDidDeclineAgreement(atIndexPath: senderIndexPath)
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		guard let docURL = NSBundle.mainBundle().URLForResource(documentName, withExtension: "rtf", subdirectory: nil, localization: nil) else
		{
			textView.text = "Couldn't find the \(documentName) file."
			return
		}
		
		do {
			let attributedString = try NSAttributedString(URL: docURL, options: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType], documentAttributes: nil)
			textView.attributedText = attributedString
		}
		catch {
			textView.text = "Couldn't read the \(documentName) file."
		}
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
