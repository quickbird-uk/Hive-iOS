//
//  OperationObserver.swift
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
    The protocol that types may implement if they wish to be notified of significant
    operation lifecycle events.
*/
protocol OperationObserver {
    
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(operation: Operation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation)
    
    /**
        Invoked as an `Operation` finishes, along with any errors produced during
        execution (or readiness evaluation).
    */
    func operationDidFinish(operation: Operation, errors: [NSError])
    
}
