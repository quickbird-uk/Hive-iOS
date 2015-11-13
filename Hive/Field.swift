//
//  Field.swift
//  Hive
//
//  Created by Animesh. on 14/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import Foundation
import CoreData

class Field: NSManagedObject
{
    //
    // MARK: - Properties
    //
    
    static let entityName = "Field"
    @NSManaged var area: NSNumber?
    @NSManaged var fieldDescription: String?
    @NSManaged var id: NSNumber?
    @NSManaged var name: String?
    @NSManaged var parentOrgID: NSNumber?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var version: String?
    @NSManaged var markedDeleted: NSNumber?

    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsField(other: Field) -> Bool
    {
        return self.id == other.id
    }
    
    private func save(newField: Field) -> Bool
    {
        id = newField.id
        area = newField.area
        fieldDescription = newField.fieldDescription
        name = newField.name
        parentOrgID = newField.parentOrgID
        createdOn = newField.createdOn
        updatedOn = newField.updatedOn
        version = newField.version
        markedDeleted = newField.markedDeleted
        
        return Data.shared.saveContext(message: "Updated field with name \(self.name).")
    }
    
    func updatedWithDetailsFromField(other: Field) -> Bool
    {
        if self.isTheSameAsField(other)
        {
        // If `other` is more recent than `self`
            if self.updatedOn!.timeIntervalSinceDate(other.updatedOn!) < 0
            {
                return save(other)
            }
            else
            {
                // TODO: - Make a POST request to push self to server
                return false
            }
        }
        else
        {
            print("\nParameter field object is not the same as the stale field object.")
            return false
        }
    }
    
    func moveToPersistentStore() -> Field?
    {
        if self.managedObjectContext == Data.shared.permanentContext
        {
            print("Field object is already stored in permanent context.")
            return self
        }
        else
        {
            let persistentField = NSEntityDescription.insertNewObjectForEntityForName(Field.entityName, inManagedObjectContext: Data.shared.permanentContext) as! Field
            print("Moving field to persistent store...")
            if persistentField.save(self)
            {
                return persistentField
            }
            return nil
        }
    }
    
    func remove()
    {
        Data.shared.permanentContext.deleteObject(self)
        Data.shared.saveContext(message: "\nDeleting field with name \(self.name) and id \(self.id).")
    }
    
    //
    // MARK: - Class Methods
    //
    
    class func temporary() -> Field
    {
        return NSEntityDescription.insertNewObjectForEntityForName(Field.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Field
    }
    
    class func getFieldWithID(id: NSNumber) -> Field?
    {
        let request = NSFetchRequest(entityName: Field.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Field]
            print("\nNumber of fields with id \(id) = \(result?.count)")
            return result?.first
        }
        catch
        {
            print("\nCouldn't find any field with ID = \(id).")
            return nil
        }
    }
    
    class func getAll() -> [Field]?
    {
        let request = NSFetchRequest(entityName: Field.entityName)
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Field]
            print("\nTotal number of field in main context = \(result?.count)")
            return result
        }
        catch
        {
            print("Couldn't fetch any fields.")
            return nil
        }
    }
    
    class func updateAllFields(newFields: [Field]) -> Int
    {
        var count = 0
        
        guard let fields = Field.getAll() else
        {
            print("Local database has no fields. Adding new fields.")
            for newField in newFields
            {
                newField.moveToPersistentStore()
            }
            return newFields.count
        }
        
        for newField in newFields
        {
            for field in fields
            {
                if field.updatedWithDetailsFromField(newField)
                {
                    count++
                }
            }
        }
        return count
    }
    
    class func deleteAll()
    {
        guard let fields = Field.getAll() else
        {
            print("Nothing to delete here in Fields.")
            return
        }
        
        for field in fields
        {
            field.remove()
        }
    }
}
