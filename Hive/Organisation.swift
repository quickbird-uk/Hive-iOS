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
				let accessToken = User.get()!.accessToken!
				var updated = false
                HiveService.shared.updateOrganisation(self, accessToken: accessToken) {
					(didUpdate, updatedOrg, error) -> Void in
					if didUpdate && error == nil {
						updated = self.save(updatedOrg!)
					}
				}
                return updated
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
    
    class func updateAll(newOrganisations: [Organisation]) -> Int
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

//
// MARK: - Quickbird API Methods
//

extension HiveService
{
	func didUpdateOrganisation(org: Organisation, fromJSON: JSON?) -> Bool
	{
		guard let json = fromJSON else
		{
			print("HiveService.didUpdateOrganisation(_: fromJSON: ) - Response JSON is nil. Organisation not updated.")
			return false
		}
		
		org.id					= json[Organisation.Key.id].numberValue
		org.name					= json[Organisation.Key.name].stringValue
		org.orgDescription		= json[Organisation.Key.orgDescription].stringValue
		org.role					= json[Organisation.Key.role].stringValue
		let createdOnString		= json[Organisation.Key.createdOn].stringValue
		org.createdOn			= self.dateFormatter.dateFromString(createdOnString)
		let updatedOnString		= json[Organisation.Key.updatedOn].stringValue
		org.updatedOn			= self.dateFormatter.dateFromString(updatedOnString)
		org.version				= json[Organisation.Key.version].stringValue
		org.markedDeleted		= json[Organisation.Key.markedDeleted].boolValue
		
		return true
	}
	
	func getAllOrganisations(accessToken token: String, completion: (didGet: Bool, orgs: [Organisation]?, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.ReadOrganisation.httpRequest(), token: token)
		
		networkConnection.makeHTTPRequest {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didGet: false, orgs: nil, error: error!.describe(details))
				return
			}
			
			guard let jsonArray = response else
			{
				completion(didGet: false, orgs: nil, error: "Server response was empty.")
				return
			}
			
			var organisations = [Organisation]()
			for info in jsonArray
			{
				let orgInfo = info.1
				let organisation            = Organisation.temporary()
				
				if self.didUpdateOrganisation(organisation, fromJSON: orgInfo) {
					organisations.append(organisation)
				}
			}
			
			completion(didGet: true, orgs: organisations, error: nil)
		}
	}
	
	func addOrganisation(org: Organisation, accessToken: String, completion: (didAdd: Bool, newOrg: Organisation?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Organisation.Key.name			: org.name!,
			Organisation.Key.orgDescription : org.orgDescription!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateOrganisation.httpRequest(), token: accessToken)
		
		networkConnection.makeHTTPRequest {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didAdd: false, newOrg: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateOrganisation(org, fromJSON: response) {
				completion(didAdd: true, newOrg: org, error: nil)
			}
			else {
				completion(didAdd: true, newOrg: nil, error: "Server response was blank. Please sync your Hive to stay up-to-date.")
			}
		}
	}
	
	func updateOrganisation(org: Organisation, accessToken: String, completion: (didUpdate: Bool, updatedOrg: Organisation?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Organisation.Key.name           : org.name!,
			Organisation.Key.orgDescription : org.orgDescription!,
			Organisation.Key.role			: org.role!,
			Organisation.Key.id             : org.id!.integerValue,
			Organisation.Key.markedDeleted	: org.markedDeleted!.boolValue,
			Organisation.Key.version			: org.version!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateOrganisation.httpRequest(urlParameter: "/\(org.id!.integerValue)"), token: accessToken)
		
		networkConnection.makeHTTPRequest {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didUpdate: false, updatedOrg: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateOrganisation(org, fromJSON: response) {
				completion(didUpdate: true, updatedOrg: org, error: nil)
			}
			else {
				completion(didUpdate: true, updatedOrg: nil, error: "Server response was blank. Please sync your Hive to stay up-to-date.")
			}
		}
	}
	
	func deleteOrganisationWithID(orgID: Int, accessToken: String, completion: (didDelete: Bool, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.DeleteOrganisation.httpRequest(urlParameter: "/\(orgID)"), token: accessToken)
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didDelete: false, error: error!.describe(details))
				return
			}
			
			completion(didDelete: true, error: nil)
		}
	}
}
























