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
				let accessToken = User.get()!.accessToken!
				var updated = false
				HiveService.shared.updateContact(self, accessToken: accessToken) {
					(didUpdate, updatedContact, error) in
					if didUpdate && error == nil {
						updated = self.save(updatedContact!)
					}
				}
                return updated
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
    
    class func getContactWithID(personID: NSNumber) -> Contact?
    {
        let request = NSFetchRequest(entityName: Contact.entityName)
        request.predicate = NSPredicate(format: "friendID == %@", personID)
        
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as! [Contact]
            print("\nNumber of contacts with id \(personID) = \(result.count)")
            return result.first
        }
        catch
        {
            print("\nCouldn't find any contacts with ID = \(personID).")
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
    
    class func updateAll(newContacts: [Contact]) -> Int
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

//
// MARK: - Quickbird API Keys
//

extension HiveService
{
	func didUpdateContact(contact: Contact, fromJSON: JSON?) -> Bool
	{
		guard let json = fromJSON else
		{
			print("HiveService.didUpdateContact(_: fromJSON: ) - Server response JSON is empty.")
			return false
		}
		
		contact.firstName       = json[Contact.Key.firstName].stringValue
		contact.lastName        = json[Contact.Key.lastName].stringValue
		contact.phone           = json[Contact.Key.phone].numberValue
		contact.friendID        = json[Contact.Key.friendID].numberValue
		contact.id              = json[Contact.Key.id].numberValue
		contact.state           = json[Contact.Key.state].stringValue
		contact.markedDeleted   = json[Contact.Key.markedDeleted].boolValue
		contact.version         = json[Contact.Key.version].stringValue
		let updateDateString    = json[Contact.Key.updatedOn].stringValue
		contact.updatedOn       = self.dateFormatter.dateFromString(updateDateString)
		let creationDateString  = json[Contact.Key.createdOn].stringValue
		contact.createdOn       = self.dateFormatter.dateFromString(creationDateString)
		
		return true
	}
	
	func getAllContacts(accessToken token: String, completion: (didGet: Bool, contacts: [Contact]?, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.ReadContacts.httpRequest(), token: token)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Nothing bad happened."
				completion(didGet: false, contacts: nil, error: error!.describe(details))
				return
			}
			
			guard let jsonArray = response else
			{
				completion(didGet: false, contacts: nil, error: "Server response JSON is empty.")
				return
			}
			
			var contacts = [Contact]()
			for info in jsonArray
			{
				let contactCard = info.1
				let contact = Contact.temporary()
				
				if self.didUpdateContact(contact, fromJSON: contactCard) {
					contacts.append(contact)
				}
			}
			
			completion(didGet: true, contacts: contacts, error: nil)
		}
	}
	
	func findContactsWithPhoneNumbers(phoneNumbers: [NSNumber], accessToken token: String, completion:(didFind: Bool, contacts: [Contact]?, error: String?) -> Void)
	{
		let body = String(phoneNumbers)
		let networkConnection = NetworkService(bodyAsPercentEncodedString: body, request: API.FindContacts.httpRequest(), token: token)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didFind: false, contacts: nil, error: error!.describe(details))
				return
			}
			
			guard let jsonArray = response else
			{
				completion(didFind: false, contacts: nil, error: "Server sent back an empty JSON.")
				return
			}
			
			var contacts = [Contact]()
			for contact in jsonArray
			{
				let contactCard = contact.1
				let newContact = Contact.temporary()
				
				if self.didUpdateContact(newContact, fromJSON: contactCard) {
					contacts.append(newContact)
				}
			}
			
			completion(didFind: true, contacts: contacts, error: nil)
		}
	}
	
	func addContactWithPersonID(contactID: Int, accessToken: String, completion: (didSendInvite: Bool, error: String?) -> Void)
	{
		let networkConnection = NetworkService(bodyAsPercentEncodedString: "\(contactID)", request: API.CreateContact.httpRequest(), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didSendInvite: false, error: error!.describe(details))
				return
			}
			
			completion(didSendInvite: true, error: nil)
		}
	}
	
	func updateContact(contact: Contact, accessToken: String, completion: (didUpdate: Bool, updatedContact: Contact?, error: String?) -> Void)
	{
		let body: NSDictionary? = [
			Contact.Key.friendID  : contact.friendID!,
			Contact.Key.state     : contact.state!,
			Contact.Key.firstName : contact.firstName!,
			Contact.Key.lastName  : contact.lastName!,
			Contact.Key.phone     : contact.phone!,
			Contact.Key.id		  : contact.id!,
			Contact.Key.version   : contact.version!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateContact.httpRequest(urlParameter: "/\(contact.id!)"), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didUpdate: false, updatedContact: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateContact(contact, fromJSON: response) {
				completion(didUpdate: true, updatedContact: contact, error: nil)
			}
			else {
				completion(didUpdate: true, updatedContact: nil, error: "Server sent an empty response. Sync your Hive now to stay up-to-date.")
			}
		}
	}
	
	func deleteContactWithConnectionID(connectionID: NSNumber?, accessToken: String, completion: (didDelete: Bool, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.DeleteContact.httpRequest(urlParameter: "/\(connectionID!)"), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].string
				completion(didDelete: false, error: error!.describe(details!))
				return
			}
			
			completion(didDelete: true, error: nil)
		}
	}
}
