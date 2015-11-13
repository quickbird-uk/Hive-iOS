//
//  Dictionary+Operations.swift
//  Hive
//
//  Abstract:
//  A convenient extension to Swift.Dictionary.
//
//  Created by Animesh. on 26/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

extension Dictionary
{
    /**
        It's not uncommon to want to turn a sequence of values into a dictionary,
        where each value is keyed by some unique identifier. This initializer will
        do that.
        
        - parameter sequence: The sequence to be iterated

        - parameter keyer: The closure that will be executed for each element in
            the `sequence`. The return value of this closure, if there is one, will
            be used as the key for the value in the `Dictionary`. If the closure
            returns `nil`, then the value will be omitted from the `Dictionary`.
    */
    init<Sequence: SequenceType where Sequence.Generator.Element == Value>(sequence: Sequence, @noescape keyMapper: Value -> Key?)
    {
        self.init()

        for item in sequence {
            if let key = keyMapper(item) {
                self[key] = item
            }
        }
    }
}
