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
            HiveService.shared.downsync(user) {
                (error) in
                if error == nil
                {
        // Sync successful. Get back to presenting view controller
                    sleep(2)
                    user.setSyncDate(NSDate())
                    self.activityIndicator.stopAnimating()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // FIXME: - Handle memory warnings
    }
}
