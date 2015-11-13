//
//  ReachabilityCondition.swift
//  Hive
//
//  Abstract:
//  This file shows an example of implementing the OperationCondition protocol.
//
//  Created by Animesh. on 26/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation
import SystemConfiguration

/**
    This is a condition that performs a very high-level reachability check.
    It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
    Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
*/
struct ReachabilityCondition: OperationCondition {
    static let hostKey = "Host"
    static let name = "Reachability"
    static let isMutuallyExclusive = false
    
    let host: NSURL
    
    
    init(host: NSURL) {
        self.host = host
    }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        ReachabilityController.requestReachability(host) { reachable in
            if reachable {
                completion(.Satisfied)
            }
            else {
                let error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: self.dynamicType.name,
                    self.dynamicType.hostKey: self.host
                ])
                
                completion(.Failed(error))
            }
        }
    }
    
}

/// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
private class ReachabilityController {
    static var reachabilityRefs = [String: SCNetworkReachability]()

    static let reachabilityQueue = dispatch_queue_create("Operations.Reachability", DISPATCH_QUEUE_SERIAL)
    
    static func requestReachability(url: NSURL, completionHandler: (Bool) -> Void) {
        if let host = url.host {
            dispatch_async(reachabilityQueue) {
                var ref = self.reachabilityRefs[host]

                if ref == nil {
                    let hostString = host as NSString
                    ref = SCNetworkReachabilityCreateWithName(nil, hostString.UTF8String)
                }
                
                if let ref = ref {
                    self.reachabilityRefs[host] = ref
                    
                    var reachable = false
                    var flags: SCNetworkReachabilityFlags = []
                    if SCNetworkReachabilityGetFlags(ref, &flags) != false {
                        /*
                            Note that this is a very basic "is reachable" check.
                            Your app may choose to allow for other considerations,
                            such as whether or not the connection would require
                            VPN, a cellular connection, etc.
                        */
                        reachable = flags.contains(.Reachable)
                    }
                    completionHandler(reachable)
                }
                else {
                    completionHandler(false)
                }
            }
        }
        else {
            completionHandler(false)
        }
    }
}
