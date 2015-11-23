//
//  SyncViewController.swift
//  Hive
//
//  Created by Animesh. on 16/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import UIKit

class SyncViewController: UIViewController
{
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var syncUpdateLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.activityIndicator.startAnimating()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        if let user = User.get()
        {
    // Sync data
            HiveService.shared.download(user) {
                (error) in
				
				guard error == nil else
				{
					self.activityIndicator.stopAnimating()
					self.syncUpdateLabel.text = "Sync failed. Taking you back..."
					sleep(3)
					self.dismissViewControllerAnimated(true, completion: nil)
					return
				}
				
        // Sync successful. Get back to presenting view controller
				user.setSyncDate(NSDate())
				self.activityIndicator.stopAnimating()
				Data.shared.saveContext(message: "Exiting sync...")
				self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // FIXME: - Handle memory warnings
    }
}
