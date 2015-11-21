//
//  Contact.swift
//  Hive
//
//  Created by Animesh. on 14/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import Foundation
import CoreData

class Contact: NSManagedObject
{
    //
    // MARK: - Properties
    //
    
    static let entityName = "Contact"
    @NSManaged var firstName: String?
    @NSManaged var id: NSNumber?
    @NSManaged var lastName: String?
    @NSManaged var friendID: NSNumber?
    @NSManaged var phone: NSNumber?
    @NSManaged var state: String?
    @NSManaged var version: String?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var markedDeleted: NSNumber?

	//
	// MARK: - API Response JSON Keys
	//
	
	struct Key
	{
		static let id				= "id"
		static let firstName			= "firstName"
		static let lastName			= "lastName"
		static let friendID			= "friendID"
		static let phone				= "phone"
		static let state				= "state"
		static let createdOn			= "createdOn"
		static let updatedOn			= "updatedOn"
		static let version			= "version"
		static let markedDeleted		= "markedDeleted"
		
		private init() {}
	}
	
    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsContact(other: Contact) -> Bool
    {
        return self.id == other.id
    }
    
    private func save(newContact: Contact) -> Bool
    {
        id              = newContact.id
        firstName       = newContact.firstName
        lastName        = newContact.lastName
        friendID        = newContact.friendID
        phone           = newContact.phone
        state           = newContact.state
        createdOn       = newContact.createdOn
        updatedOn       = newContact.updatedOn
        version         = newContact.version
        markedDeleted   = newContact.markedDeleted
        
        return Data.shared.saveContext(message: "Contact with last name \(self.lastName) saved.")
    }
    
    func updatedWithDetailsFromContact(other: Contact) -> Bool
    {
        if self.isTheSameAsContact(other)
        {
            if other.updatedOn!.timeIntervalSinceDate(self.updatedOn!) > 0
            {
                return save(other)
            }
            else
            {
                // TODO: - Make a POST request to push self to server
                return true
            }
        }
        return false
    }
    
    func moveToPersistentStore() -> Contact?
    {
        if self.managedObjectContext == Data.shared.permanentContext
        {
            print("Contact object is already stored in permanent context.")
            return self
        }
        else
        {
            let persistentContact = NSEntityDescription.insertNewObjectForEntityForName(Contact.entityName, inManagedObjectContext: Data.shared.permanentContext) as! Contact
            print("Moving contact to persistent store...")
            if persistentContact.save(self)
            {
                return persistentContact
            }
            return nil
        }
    }
    
    func remove()
    {
        Data.shared.permanentContext.deleteObject(self)
        Data.shared.saveContext(message: "\nDeleting Contact with last name \(self.lastName) and id \(self.id).")
    }
    
    //
    // MARK: - Class Methods
    //
    
    class func temporary() -> Contact
    {
        let tempContact = NSEntityDescription.insertNewObjectForEntityForName(Contact.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Contact
		tempContact.updatedOn = NSDate()
		tempContact.createdOn = NSDate()
		return tempContact
    }
    
    class func getContactWithID(id: NSNumber) -> Contact?
    {
        let request = NSFetchRequest(entityName: Contact.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as! [Contact]
            print("\nNumber of contacts with id \(id) = \(result.count)")
            return result.first
        }
        catch
        {
            print("\nCouldn't find any contacts with ID = \(id).")
            return nil
        }
    }
    
	class func getAll(filter: String? = nil) -> [Contact]?
    {
        let request = NSFetchRequest(entityName: Contact.entityName)
		
		if filter != nil
		{
			switch filter!
			{
				case "friends" :
					request.predicate = NSPredicate(format: "state == %@", "Fr")
					print("Fetching contacts using Friends filter.")
				default:
					break
			}
			
		}
		
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Contact]
            print("\nTotal number of filtered contacts in main context = \(result?.count)")
			if result?.count > 0 {
				return result
			}
			else {
				return nil
			}
        }
        catch
        {
            print("Couldn't fetch any contacts.")
            return nil
        }
    }
    
    class func updateAllContacts(newContacts: [Contact]) -> Int
    {
        var count = 0
		var contactToSync: Contact!
		var matchFound = false
        
        guard let contacts = Contact.getAll() else
        {
            print("Local database has no contacts. Adding new contacts.")
            for contact in newContacts
            {
                print(contact)
                contact.moveToPersistentStore()
            }
            return newContacts.count
        }
        
		for newContact in newContacts {
			for contact in contacts {
				if contact.isTheSameAsContact(newContact) {
					matchFound = true
					contactToSync = contact
					break
				}
			}
			if matchFound {
				contactToSync.updatedWithDetailsFromContact(newContact)
				count++
			}
			else {
				newContact.moveToPersistentStore()
				count++
			}
		}
		
        return count
    }
    
    class func deleteAll()
    {
        guard let contacts = Contact.getAll() else
        {
            print("Nothing to delete here in Contacts.")
            return
        }
        
        for contact in contacts
        {
            contact.remove()
        }
    }
}
