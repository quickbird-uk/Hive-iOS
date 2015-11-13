//
//  URLSessionTaskOperation.swift
//  Hive
//
//  Abstract:
//  This file Shows how to lift operation-like objects in to the NSOperation world.
//
//  Created by Animesh. on 26/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation

private var URLSessionTaksOperationKVOContext = 0

/**
    `URLSessionTaskOperation` is an `Operation` that lifts an `NSURLSessionTask`
    into an operation.

    Note that this operation does not participate in any of the delegate callbacks \
    of an `NSURLSession`, but instead uses Key-Value-Observing to know when the
    task has been completed. It also does not get notified about any errors that
    occurred during execution of the task.

    An example usage of `URLSessionTaskOperation` can be seen in the `DownloadEarthquakesOperation`.
*/
class URLSessionTaskOperation: Operation
{
    let task: NSURLSessionTask
    
    init(task: NSURLSessionTask)
    {
        assert(task.state == .Suspended, "Tasks must be suspended.")
        self.task = task
        super.init()
    }
    
    override func execute() {
        assert(task.state == .Suspended, "Task was resumed by something other than \(self).")

        task.addObserver(self, forKeyPath: "state", options: [], context: &URLSessionTaksOperationKVOContext)
        
        task.resume()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &URLSessionTaksOperationKVOContext else { return }
        
        if object === task && keyPath == "state" && task.state == .Completed {
            task.removeObserver(self, forKeyPath: "state")
            finish()
        }
    }
    
    override func cancel() {
        task.cancel()
        super.cancel()
    }
}
