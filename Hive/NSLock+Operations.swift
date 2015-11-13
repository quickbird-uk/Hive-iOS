//
//  NSLock+Operations.swift
//  Hive
//
//  Abstract:
//  An extension to NSLock to simplify executing critical code.
//
//  Created by Animesh. on 28/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation

extension NSLock {
    func withCriticalScope<T>(@noescape block: Void -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
