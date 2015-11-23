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
    @NSManaged var onOrganisationID: NSNumber?
    @NSManaged var personID: NSNumber?
    @NSManaged var phone: NSNumber?
    @NSManaged var role: String?
    @NSManaged var version: String?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var markedDeleted: NSNumber?
	
	//
	// MARK: - API Response JSON Keys
	//
	
	struct Key
	{
		static let id					= "id"
		static let firstName				= "firstName"
		static let lastName				= "lastName"
		static let onOrganisationID		= "onOrganisationID"
		static let personID				= "personID"
		static let phone					= "phone"
		static let role					= "role"
		static let createdOn				= "createdOn"
		static let updatedOn				= "updatedOn"
		static let version				= "version"
		static let markedDeleted			= "markedDeleted"
		
		private init() { }
	}
	
    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsStaff(other: Staff) -> Bool
    {
        return self.id == other.id
    }
    
    private func save(newStaff: Staff) -> Bool
    {
        id					= newStaff.id
        firstName			= newStaff.firstName
        lastName				= newStaff.lastName
        onOrganisationID    = newStaff.onOrganisationID
        personID				= newStaff.personID
        phone				= newStaff.phone
        role					= newStaff.role
        createdOn			= newStaff.createdOn
        updatedOn			= newStaff.updatedOn
        version				= newStaff.version
        markedDeleted		= newStaff.markedDeleted
        
        return Data.shared.saveContext(message: "Staff with last name \(self.lastName) saved.")
    }
    
    func updatedWithDetailsFromStaff(other: Staff) -> Bool
    {
        if self.isTheSameAsStaff(other)
        {
			print(self)
			if other.updatedOn!.timeIntervalSinceDate(self.updatedOn!) > 0
            {
                return save(other)
            }
            else
            {
				let accessToken = User.get()!.accessToken!
				var updated = false
				HiveService.shared.updateStaff(self, accessToken: accessToken) {
					(didUpdate, updatedStaff, error) in
					if didUpdate && error == nil {
						updated = self.save(updatedStaff!)
					}
				}
				return updated
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
        let tempStaff = NSEntityDescription.insertNewObjectForEntityForName(Staff.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Staff
		tempStaff.createdOn = NSDate()
		tempStaff.updatedOn = NSDate()
		return tempStaff
    }
    
    class func getStaffWithID(personID: NSNumber) -> Staff?
    {
        let request = NSFetchRequest(entityName: Staff.entityName)
        request.predicate = NSPredicate(format: "personID == %@", personID)
        
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as! [Staff]
            print("\nNumber of staff with id \(personID) = \(result.count)")
            return result.first
        }
        catch
        {
            print("\nCouldn't find any staff with ID = \(personID).")
            return nil
        }
    }
	
    class func getAll() -> [Staff]?
    {
        let request = NSFetchRequest(entityName: Staff.entityName)
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Staff]
            print("\nTotal number of staff in main context = \(result?.count)")
			if result?.count > 0 {
				return result
			}
			else {
				return nil
			}
        }
        catch
        {
            print("Couldn't fetch any staff.")
            return nil
        }
    }
    
    class func updateAll(newStaffs: [Staff]) -> Int
    {
        var count = 0
		var staffToSync: Staff!
		var matchFound = false
        
        guard let staffs = Staff.getAll() else
        {
            print("Local database has no staff. Adding new staff.")
            for newStaff in newStaffs
            {
                newStaff.moveToPersistentStore()
            }
            return newStaffs.count
        }
        
		for newStaff	 in newStaffs {
			for staff in staffs {
				if staff.isTheSameAsStaff(newStaff) {
					matchFound = true
					staffToSync = staff
					break
				}
			}
			if matchFound {
				staffToSync.updatedWithDetailsFromStaff(newStaff)
				count++
			}
			else {
				newStaff.moveToPersistentStore()
				count++
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
	
	//
	// MARK: - Roles & Authorisations
	//
	
	enum Role: String
	{
		case Owner		= "Owner"
		case Manager		= "Manager"
		case Specialist = "Specialist"
		case Crew		= "Crew"
		
		static var allRoles: [String] {
			get {
				return [
					Owner.rawValue,
					Manager.rawValue,
					Specialist.rawValue,
					Crew.rawValue
				]
			}
		}
	}
	
	var canManageOrganisation: Bool {
		get {
			return role! == Role.Owner.rawValue
		}
	}
	
	var canManageStaff: Bool {
		get {
			return role! == Role.Manager.rawValue
		}
	}
	
	var canManageTasks: Bool {
		get {
			return role! == Role.Specialist.rawValue
		}
	}
}

//
// MARK: - Quickbird API Methods
//

extension HiveService
{
	func didUpdateStaff(staff: Staff, fromJSON: JSON?) -> Bool
	{
		guard let json = fromJSON else
		{
			print("HiveService.didUpdateStaff(_: fromJSON: ) - Server sent nothing in response.")
			return false
		}
		
		staff.personID			= json[Staff.Key.personID].numberValue
		staff.onOrganisationID  = json[Staff.Key.onOrganisationID].numberValue
		staff.role				= json[Staff.Key.role].stringValue
		staff.firstName			= json[Staff.Key.firstName].stringValue
		staff.lastName			= json[Staff.Key.lastName].stringValue
		staff.phone				= json[Staff.Key.phone].numberValue
		staff.id					= json[Staff.Key.id].numberValue
		let createdOnString		= json[Staff.Key.createdOn].stringValue
		staff.createdOn			= self.dateFormatter.dateFromString(createdOnString)
		let updatedOnString		= json[Staff.Key.updatedOn].stringValue
		staff.updatedOn			= self.dateFormatter.dateFromString(updatedOnString)
		staff.version			= json[Staff.Key.version].stringValue
		staff.markedDeleted		= json[Staff.Key.markedDeleted].boolValue
		
		return true
	}
	
	func getAllStaff(accessToken accessToken: String, completion: (didGet: Bool, staffs: [Staff]?, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.ReadStaff.httpRequest(), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didGet: false, staffs: nil, error: error!.describe(details))
				return
			}
			
			guard let jsonArray = response else
			{
				completion(didGet: false, staffs: nil, error: "Server sent nothing in response.")
				return
			}
			
			var staffs = [Staff]()
			for info in jsonArray
			{
				let staffInfo = info.1
				let staff = Staff.temporary()
				
				if self.didUpdateStaff(staff, fromJSON: staffInfo) {
					staffs.append(staff)
				}
			}
			
			completion(didGet: true, staffs: staffs, error: nil)
		}
	}
	
	func addStaff(staff: Staff, accessToken: String, completion: (didAdd: Bool, newStaff: Staff?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Staff.Key.personID          : staff.personID!,
			Staff.Key.onOrganisationID  : staff.onOrganisationID!,
			Staff.Key.role              : staff.role!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateStaff.httpRequest(), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didAdd: false, newStaff: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateStaff(staff, fromJSON: response) {
				completion(didAdd: true, newStaff: staff, error: nil)
			}
			else {
				completion(didAdd: true, newStaff: nil, error: "Server sent nothing in response. Sync your Hive now to stay up-to-date.")
			}
		}
	}
	
	func updateStaff(staff: Staff, accessToken: String,completion: (didUpdate: Bool, updatedStaff: Staff?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Staff.Key.personID          : staff.personID!,
			Staff.Key.onOrganisationID  : staff.onOrganisationID!,
			Staff.Key.role              : staff.role!,
			Staff.Key.firstName         : staff.firstName!,
			Staff.Key.lastName          : staff.lastName!,
			Staff.Key.phone             : staff.phone!,
			Staff.Key.id				    : staff.id!,
			Staff.Key.version			: staff.version!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateStaff.httpRequest(urlParameter: "/\(staff.id!.integerValue)"), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didUpdate: false, updatedStaff: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateStaff(staff, fromJSON: response) {
				completion(didUpdate: true, updatedStaff: staff, error: nil)
			}
			else {
				completion(didUpdate: true, updatedStaff: nil, error: "Server sent an empty response. Sync your Hive now to stay up-to-date.")
			}
		}
	}
	
	func deleteStaffWithConnectionID(connectionID: Int, accessToken: String, completion: (didDelete: Bool, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.DeleteStaff.httpRequest(urlParameter: "/\(connectionID)"), token: accessToken)
		
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
