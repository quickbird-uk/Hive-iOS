//
//  MutuallyExclusive.swift
//  Hive
//
//  Abstract:
//  This file shows an example of implementing the OperationCondition protocol.
//
//  Created by Animesh. on 26/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation

/// A generic condition for describing kinds of operations that may not execute concurrently.
struct MutuallyExclusive<T>: OperationCondition
{
    static var name: String {
        return "MutuallyExclusive<\(T.self)>"
    }

    static var isMutuallyExclusive: Bool {
        return true
    }
    
    init() { }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(.Satisfied)
    }
}

/**
    The purpose of this enum is to simply provide a non-constructible
    type to be used with `MutuallyExclusive<T>`.
*/
enum Alert { }

/// A condition describing that the targeted operation may present an alert.
typealias AlertPresentation = MutuallyExclusive<Alert>
