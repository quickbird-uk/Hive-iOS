//
//  Organisation.swift
//  Hive
//
//  Created by Animesh. on 22/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import Foundation
import CoreData

class Organisation: NSManagedObject
{
    //
    // MARK: - Properties
    //
    
    static let entityName = "Organisation"
    @NSManaged var id: NSNumber?
    @NSManaged var name: String?
    @NSManaged var orgDescription: String?
    @NSManaged var role: String?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var version: String?
    @NSManaged var markedDeleted: NSNumber?
    
    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsOrganisation(other: Organisation) -> Bool
    {
        return self.id == other.id
    }
    
    private func save(newOrg: Organisation) -> Bool
    {
        id = newOrg.id
        name = newOrg.name
        orgDescription = newOrg.orgDescription
        role = newOrg.role
        createdOn = newOrg.createdOn
        updatedOn = newOrg.updatedOn
        version = newOrg.version
        markedDeleted = newOrg.markedDeleted
        
        return Data.shared.saveContext(message: "Updated organization with name \(self.name).")
    }
    
    func updatedWithDetailsFromOrganisation(other: Organisation) -> Bool
    {
        if self.isTheSameAsOrganisation(other)
        {
        // If other is more recent than self
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
            print("Parameter object is not the same as the stale object.")
            return false
        }
    }
    
    func moveToPersistentStore() -> Organisation?
    {
        if self.managedObjectContext == Data.shared.permanentContext
        {
            print("User object is already stored in permanent context.")
            return self
        }
        else
        {
            let persistentOrg = NSEntityDescription.insertNewObjectForEntityForName(Organisation.entityName, inManagedObjectContext: Data.shared.permanentContext) as! Organisation
            print("Moving user to persistent store...")
            if persistentOrg.save(self)
            {
                return persistentOrg
            }
            return nil
        }
    }
    
    func remove()
    {
        Data.shared.permanentContext.deleteObject(self)
        Data.shared.saveContext(message: "\nDeleting organization with name \(self.name) and id \(self.id).")
    }
    
    //
    // MARK: - Class Methods
    //
    
    class func temporary() -> Organisation
    {
        return NSEntityDescription.insertNewObjectForEntityForName(Organisation.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Organisation
    }
    
    class func getAll() -> [Organisation]?
    {
        let request = NSFetchRequest(entityName: Organisation.entityName)
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Organisation]
            print("\nTotal number of organizations in main context = \(result?.count)")
            return result
        }
        catch
        {
            print("Couldn't fetch any organisations.")
            return nil
        }
    }
    
    class func getOrganisationWithID(id: NSNumber) -> Organisation?
    {
        let request = NSFetchRequest(entityName: Organisation.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Organisation]
            print("\nNumber of organizations with id \(id) = \(result?.count)")
            return result?.first
        }
        catch
        {
            print("\nCouldn't find any organisation with that ID.")
            return nil
        }
    }
    
    class func updateAllOrganisations(newOrganisations: [Organisation]) -> Int
    {
        var count = 0
        
        guard let organisations = Organisation.getAll() else
        {
            print("Local database has no contacts. Adding new contacts.")
            for newOrg in newOrganisations
            {
                newOrg.moveToPersistentStore()
            }
            return newOrganisations.count
        }
        
        for newOrg in newOrganisations
        {
            for organisation in organisations
            {
                if organisation.updatedWithDetailsFromOrganisation(newOrg)
                {
                    count++
                }
            }
        }
        return count
    }
    
    class func deleteAll()
    {
        guard let organisations = Organisation.getAll() else
        {
            print("Nothing to delete here in Organisations.")
            return
        }
        
        for org in organisations
        {
            org.remove()
        }
    }
}

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

