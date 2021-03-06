//
//  TimeoutObserver.swift
//  Hive
//
//  Abstract:
//  This file defines the OperationObserver protocol.
//
//  Created by Animesh. on 28/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation

/**
    `TimeoutObserver` is a way to make an `Operation` automatically time out and
    cancel after a specified time interval.
*/
struct TimeoutObserver: OperationObserver {
    // MARK: Properties

    static let timeoutKey = "Timeout"
    
    private let timeout: NSTimeInterval
    
    // MARK: Initialization
    
    init(timeout: NSTimeInterval) {
        self.timeout = timeout
    }
    
    // MARK: OperationObserver
    
    func operationDidStart(operation: Operation) {
        // When the operation starts, queue up a block to cause it to time out.
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))

        dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            /*
                Cancel the operation if it hasn't finished and hasn't already
                been cancelled.
            */
            if !operation.finished && !operation.cancelled {
                let error = NSError(code: .ExecutionFailed, userInfo: [
                    self.dynamicType.timeoutKey: self.timeout
                ])

                operation.cancelWithError(error)
            }
        }
    }

    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        // No op.
    }

    func operationDidFinish(operation: Operation, errors: [NSError]) {
        // No op.
    }
}
