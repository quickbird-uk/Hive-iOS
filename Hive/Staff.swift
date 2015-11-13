//
//  Staff.swift
//  Hive
//
//  Created by Animesh. on 14/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import Foundation
import CoreData

class Staff: NSManagedObject
{
    //
    // MARK: - Properties
    //
    
    static let entityName = "Staff"
    @NSManaged var firstName: String?
    @NSManaged var id: NSNumber?
    @NSManaged var lastName: String?
    @NSManaged var organization: NSNumber?
    @NSManaged var personID: NSNumber?
    @NSManaged var phone: NSNumber?
    @NSManaged var role: String?
    @NSManaged var version: String?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var markedDeleted: NSNumber?
    
    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsStaff(other: Staff) -> Bool
    {
        let request = NSFetchRequest(entityName: Staff.entityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", other.id!)
        
        let errorPointer: NSErrorPointer = nil
        let count = Data.shared.permanentContext.countForFetchRequest(request, error: errorPointer)
        
        return Bool(count)
    }
    
    private func save(newStaff: Staff) -> Bool
    {
        id              = newStaff.id
        firstName       = newStaff.firstName
        lastName        = newStaff.lastName
        organization    = newStaff.organization
        personID        = newStaff.personID
        phone           = newStaff.phone
        role            = newStaff.role
        createdOn       = newStaff.createdOn
        updatedOn       = newStaff.updatedOn
        version         = newStaff.version
        markedDeleted   = newStaff.markedDeleted
        
        return Data.shared.saveContext(message: "Staff with last name \(self.lastName) saved.")
    }
    
    func updatedWithDetailsFromStaff(other: Staff) -> Bool
    {
        if self.isTheSameAsStaff(other)
        {
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
            print("\nParameter staff object is not the same as the stale staff object.")
            return false
        }
    }
    
    func moveToPersistentStore() -> Staff?
    {
        if self.managedObjectContext == Data.shared.permanentContext
        {
            print("Staff object is already stored in permanent context.")
            return self
        }
        else
        {
            let persistentStaff = NSEntityDescription.insertNewObjectForEntityForName(Staff.entityName, inManagedObjectContext: Data.shared.permanentContext) as! Staff
            print("Moving staff to persistent store...")
            if persistentStaff.save(self)
            {
                return persistentStaff
            }
            return nil
        }
    }
    
    func remove()
    {
        Data.shared.permanentContext.deleteObject(self)
        Data.shared.saveContext(message: "\nDeleting staff with last name \(self.lastName) and id \(self.id).")
    }
    
    //
    // MARK: - Class Methods
    //
    
    class func temporary() -> Staff
    {
        return NSEntityDescription.insertNewObjectForEntityForName(Staff.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Staff
    }
    
    class func getStaffWithID(id: NSNumber) -> Staff?
    {
        let request = NSFetchRequest(entityName: Staff.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as! [Staff]
            print("\nNumber of staff with id \(id) = \(result.count)")
            return result.first
        }
        catch
        {
            print("\nCouldn't find any staff with ID = \(id).")
            return nil
        }
    }
    
    class func getAll() -> [Staff]?
    {
        let request = NSFetchRequest(entityName: Staff.entityName)
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Staff]
            print("\nTotal number of staff in main context = \(result?.count)")
            return result
        }
        catch
        {
            print("Couldn't fetch any staff.")
            return nil
        }
    }
    
    class func updateAllStaff(newStaffs: [Staff]) -> Int
    {
        var count = 0
        
        guard let staffs = Staff.getAll() else
        {
            print("Local database has no staff. Adding new staff.")
            for newStaff in newStaffs
            {
                newStaff.moveToPersistentStore()
            }
            return newStaffs.count
        }
        
        for newStaff in newStaffs
        {
            for staff in staffs
            {
                if staff.updatedWithDetailsFromStaff(newStaff)
                {
                    count++
                }
            }
        }
        return count
    }
    
    class func deleteAll()
    {
        guard let staffs = Staff.getAll() else
        {
            print("Nothing to delete here in Staff.")
            return
        }
        
        for staff in staffs
        {
            staff.remove()
        }
    }
}
