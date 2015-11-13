//
//  Operation.swift
//  Hive
//
//  Created by Animesh. on 26/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation

class Operation: NSOperation
{
    //
    // MARK: - Properties
    //
    
    /// Private storage for the 'state' property that will be KVO observed
    private var _state = State.Initialized
    
    /// A lock to guard reads and writes to the '_state' property
    private let stateLock = NSLock()
    
    private var state: State {
        get {
            return stateLock.withCriticalScope {
                _state
            }
        }
        set(newState) {
            willChangeValueForKey("state")
            
            stateLock.withCriticalScope {
                guard _state != .Finished else
                {
                    return
                }
                
                assert(_state.canTransitionToState(newState), "Performing invalid state transition.")
                _state = newState
            }
            
            didChangeValueForKey("state")
        }
    }
    
    // Extend definition of "readiness"
    override var ready: Bool {
        switch state
        {
            case .Initialized:
                // If the operation has been cancelled, "isReady" should return true
                return cancelled
            
            case .Pending:
                // If the operation has been cancelled, "isReady" should return true
                guard !cancelled else
                {
                    return true
                }
            
                // If super isReady, conditions can be evaluated
                if super.ready
                {
                    evaluateConditions()
                }
            
                // Until conditions have been evaluated, "isReady returns false
                return false
            
            case .Ready:
                return super.ready || cancelled
            
            default:
                return false
        }
    }
    
    var userInitiated: Bool {
        get {
            return qualityOfService == .UserInitiated
        }
        
        set {
            assert(state < State.Executing, "Cannot modify userInitiated after execution has begun.")
            qualityOfService = newValue ? .UserInitiated : .Default
        }
    }
    
    override var executing: Bool {
        return state == .Executing
    }
    
    override var finished: Bool {
        return state == .Finished
    }
    
    private(set) var conditions = [OperationCondition]()
    private(set) var observers = [OperationObserver]()
    private var _internalErrors = [NSError]()
    
    // A private property to ensure we only notify the
    // observers once that the operation has finished
    private var hasFinishedAlready = false
    
    //
    // MARK: - Key-Value Observing
    //
    // Use the KVO mechanism to indicate that changes to "state"
    // affect other properties as well
    //
    
    class func keyPathsForValuesAffectingIsReady() -> Set<NSObject>
    {
        return ["state"]
    }
    
    class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject>
    {
        return ["state"]
    }
    
    class func keyPathsForValuesAffectingIsEnding() -> Set<NSObject>
    {
        return ["state"]
    }
    
    //
    // MARK: - State Management
    //
    
    private enum State: Int, Comparable
    {
        case Initialized
        
        /// Ready to begin evaluating conditions
        case Pending
        
        case EvaluatingConditions
        
        /// All evaluating conditions satisfied
        /// ready to execute
        case Ready
        
        case Executing
        
        /// Execution has finished, but the operation has
        /// not yet notified the queue of this
        case Finishing
        
        case Finished
        
        func canTransitionToState(target: State) -> Bool
        {
            switch (self, target)
            {
                case (.Initialized, .Pending):
                    return true
                case (.Pending, .EvaluatingConditions):
                    return true
                case (.EvaluatingConditions, .Ready):
                    return true
                case (.Ready, .Executing):
                    return true
                case (.Ready, .Finishing):
                    return true
                case (.Executing, .Finishing):
                    return true
                case (.Finishing, .Finished):
                    return true
                default:
                    return false
            }
        }
    }
    
    //
    // MARK: - Methods
    //
    
    func willEnqueue()
    {
        state = .Pending
    }
    
    private func evaluateConditions()
    {
        assert(state == .Pending && !cancelled, "evaluateConditions() was called out-of-order")
        
        state = .EvaluatingConditions
        
        OperationConditionEvaluator.evaluate(conditions, operation: self) {
            failures in
            self._internalErrors.appendContentsOf(failures)
            self.state = .Ready
        }
    }
    
    //
    // MARK: - Observers and Conditions
    //
    
    func addCondition(condition: OperationCondition)
    {
        assert(state < .EvaluatingConditions, "Cannot modify conditions after execution has begun.")
        conditions.append(condition)
    }
    
    func addObserver(observer: OperationObserver)
    {
        assert(state < .Executing, "Cannot modify observers after execution has begun.")
        observers.append(observer)
    }
    
    override func addDependency(operation: NSOperation)
    {
        assert(state < .Executing, "Dependencies cannot be modified after execution has begun.")
        super.addDependency(operation)
    }
    
    //
    // MARK: - Execution and Cancellation
    //
    
    override final func start()
    {
        // NSOperation.start() contains important logic that shouldn't be bypassed
        super.start()
        
        // If operation has been cancelled, enter the "Finished" state
        if cancelled
        {
            finish()
        }
    }
    
    override final func main()
    {
        assert(state == .Ready, "This operation must be performed on an operation queue.")
        
        if _internalErrors.isEmpty && !cancelled
        {
            state = .Executing
            
            for observer in observers
            {
                observer.operationDidStart(self)
            }
            
            execute()
        }
        else
        {
            finish()
        }
    }
    
    /**
    `execute()` is the entry point of execution for all `Operation` subclasses.
    If you subclass `Operation` and wish to customize its execution, you would
    do so by overriding the `execute()` method.
    
    At some point, your `Operation` subclass must call one of the "finish"
    methods defined below; this is how you indicate that your operation has
    finished its execution, and that operations dependent on yours can re-evaluate
    their readiness state.
    */
    func execute()
    {
        print("\(self.dynamicType) must override 'execute()'.")
        finish()
    }
    
    func cancelWithError(error: NSError? = nil)
    {
        if let error = error {
            _internalErrors.append(error)
        }
        
        cancel()
    }
    
    final func produceOperation(operation: NSOperation)
    {
        for observer in observers
        {
            observer.operation(self, didProduceOperation: operation)
        }
    }
    
    //
    // MARK: - Finishing
    //
    
    final func finishWithError(error: NSError?)
    {
        if let error = error {
            finish([error])
        }
        else {
            finish()
        }
    }
    
    final func finish(errors: [NSError] = [])
    {
        if !hasFinishedAlready {
            hasFinishedAlready = true
            state = .Finishing
            
            let combinedErrors = _internalErrors + errors
            finished(combinedErrors)
            
            for observer in observers
            {
                observer.operationDidFinish(self, errors: combinedErrors)
            }
            
            state = .Finished
        }
    }
    
    func finished(errors: [NSError])
    {
        // No op.
    }
    
    override final func waitUntilFinished()
    {
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.")
    }
}

private func <(lhs: Operation.State, rhs: Operation.State) -> Bool
{
    return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: Operation.State, rhs: Operation.State) -> Bool
{
    return lhs.rawValue == rhs.rawValue
}



















