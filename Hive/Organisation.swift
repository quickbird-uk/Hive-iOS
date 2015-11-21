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
	// MARK: - API Response JSON Keys
	//
	
	struct Key
	{
		static let id				= "id"
		static let name				= "name"
		static let orgDescription	= "orgDescription"
		static let role				= "role"
		static let createdOn			= "createdOn"
		static let updatedOn			= "updatedOn"
		static let version			= "version"
		static let markedDeleted		= "markedDeleted"
		
		private init() { }
	}
	
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
			if other.updatedOn!.timeIntervalSinceDate(self.updatedOn!) > 0
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
            print("Parameter farm objects \(self.name) is not the same as the farm object being updated.")
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
        let tempOrg = NSEntityDescription.insertNewObjectForEntityForName(Organisation.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Organisation
		tempOrg.updatedOn = NSDate()
		tempOrg.createdOn = NSDate()
		return tempOrg
    }
    
	class func getAll(filter: String? = nil) -> [Organisation]?
    {
        let request = NSFetchRequest(entityName: Organisation.entityName)
		
		if filter != nil
		{
			switch filter!
			{
				case "owned":
					request.predicate = NSPredicate(format: "role == %@", "Owner")
					print("Fetching organisations using Owned filter")
				default:
					break
			}
			
		}
		
		do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Organisation]
            print("\nTotal number of organizations in main context = \(result?.count)")
			if result?.count > 0 {
				return result
			}
			else {
				return nil
			}
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
		var matchFound = false
		var orgToSync: Organisation!
        
        guard let organisations = Organisation.getAll() else
        {
            print("Local database has no organisations. Adding new organisations.")
            for newOrg in newOrganisations
            {
                newOrg.moveToPersistentStore()
				count++
            }
            return newOrganisations.count
        }
		
		for newOrg in newOrganisations {
			for org in organisations {
				if org.isTheSameAsOrganisation(newOrg) {
					matchFound = true
					orgToSync = org
					break
				}
			}
			if matchFound {
				orgToSync.updatedWithDetailsFromOrganisation(newOrg)
				count++
			}
			else {
				newOrg.moveToPersistentStore()
				count++
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

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

