//
//  BlockOperation.swift
//  Hive
//
//  Created by Animesh. on 28/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation

/// A closure type that takes a closure as its parameter
typealias OperationBlock = (Void -> Void) -> Void

/// A subclass of `Operation` to execute a closure
class BlockOperation: Operation
{
    private let block: OperationBlock?
    
/**
    The designated initializer. 

    - parameter block: The closure to run when the operation executes. This
        closure will run on an arbitrary queue. The parameter passed to the 
        block **MUST** be invoked by your code, or else the `BlockOperation`
        will never finish executing. If this parameter is `nil`, the operation
        will immediately finish
*/
    init(block: OperationBlock? = nil)
    {
        self.block = block
        super.init()
    }
    
/**
    A convenience initializer to excute a block on the main queue.

    - parameter mainQueueBlock: The block to execute on the main queue. Not that
        this block does not have a "continuation" block to execute (unlike the 
        designated initializer). The operation will be automatically ended after
        the `mainQueueBlock` is executed.
*/
    convenience init(mainQueueBlock: dispatch_block_t)
    {
        self.init(block: {
            continuation in
            dispatch_async(dispatch_get_main_queue()) {
                mainQueueBlock()
                continuation()
            }
        })
    }
    
    override func execute()
    {
        guard let block = self.block else
        {
            finish()
            return
        }
        
        block {
            self.finish()
        }
    }
}
