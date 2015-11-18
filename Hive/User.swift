//
//  User.swift
//  Hive
//
//  Created by Animesh. on 14/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject
{
    //
    // MARK: - Properties
    //
    
    static let entityName = "User"
    
    var passcode: String?
    @NSManaged var id: NSNumber?
    @NSManaged var accessExpiresOn: NSDate?
    @NSManaged var accessToken: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var phone: NSNumber?
    @NSManaged var isVerified: NSNumber?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var version: String?
    @NSManaged var markedDeleted: NSNumber?
    @NSManaged var lastSync: NSDate?
	
	//
	// MARK: - API Response JSON Keys
	//
	
	struct Key
	{
		static let id						= "id"
		static let firstName					= "firstName"
		static let lastName					= "lastName"
		static let phone						= "phone"
		static let isVerified				= "isVerified"
		static let createdOn					= "createdOn"
		static let updatedOn					= "updatedOn"
		static let version					= "version"
		static let markedDeleted				= "markedDeleted"
		static let lastSync					= "lastSync"
		static let accessExpiresOn			= "accessExpiresOn"
		static let accessExpiresInSeconds	= "accessExpiresInSeconds"
		static let accessToken				= "accessToken"
		static let password					= "password"
		
		private init() { }
	}
	
    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsUser(other: User) -> Bool
    {
        return self.id == other.id
    }
    
    private func save(newUser: User) -> Bool
    {
        passcode            = newUser.passcode
        id                  = newUser.id
        accessExpiresOn     = newUser.accessExpiresOn
        accessToken         = newUser.accessToken
        firstName           = newUser.firstName
        lastName            = newUser.lastName
        phone               = newUser.phone
        isVerified          = newUser.isVerified
        createdOn           = newUser.createdOn
        updatedOn           = newUser.updatedOn
        version             = newUser.version
        markedDeleted       = newUser.markedDeleted
        
        return Data.shared.saveContext(message: "\nUpdating user details.")
    }
    
    func updatedWithDetailsFromUser(other: User) -> Bool
    {
        if self.isTheSameAsUser(other)
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
            print("\nParameter user object is not the same as the stale user object.")
            return false
        }
    }
    
    func moveToPersistentStore() -> User?
    {
        if self.managedObjectContext == Data.shared.permanentContext
        {
            print("User object is already stored in permanent context.")
            return self
        }
        else
        {
            let persistentUser = NSEntityDescription.insertNewObjectForEntityForName(User.entityName, inManagedObjectContext: Data.shared.permanentContext) as! User
            print("Moving user to persistent store...")
            if persistentUser.save(self)
            {
                return persistentUser
            }
            return nil
        }
    }
    
    func remove()
    {
        Data.shared.permanentContext.deleteObject(self)
        Data.shared.saveContext(message: "\nDeleting user with last name \(self.lastName) and id \(self.id).")
    }
    
    func setSyncDate(date: NSDate)
    {
        self.lastSync = date
    }
    
    //
    // MARK: - Class Methods
    //
    
    class func temporary() -> User
    {
        let tempUser = NSEntityDescription.insertNewObjectForEntityForName(User.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! User
		tempUser.updatedOn = NSDate()
		tempUser.createdOn = NSDate()
		return tempUser
    }
    
    class func get() -> User?
    {
        let request = NSFetchRequest(entityName: User.entityName)
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [User]
            print("\nNumber of users = \(result?.count)")
			if result?.count > 0 {
				return result?.first
			}
			else {
				return nil
			}
        }
        catch
        {
            print("Couldn't fetch any users.")
            return nil
        }
    }
    
    class func deleteAll()
    {
        guard let user = User.get() else
        {
            print("Nothing to delete here in Users.")
            return
        }
        user.remove()
    }
}
