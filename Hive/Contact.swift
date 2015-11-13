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
    @NSManaged var personID: NSNumber?
    @NSManaged var phone: NSNumber?
    @NSManaged var state: String?
    @NSManaged var version: String?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var markedDeleted: NSNumber?

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
        personID        = newContact.personID
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
            if self.updatedOn!.timeIntervalSinceDate(other.updatedOn!) < 0
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
        return NSEntityDescription.insertNewObjectForEntityForName(Contact.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Contact
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
    
    class func getAll() -> [Contact]?
    {
        let request = NSFetchRequest(entityName: Contact.entityName)
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Contact]
            print("\nTotal number of contacts in main context = \(result?.count)")
            if result?.count > 0
            {
                return result
            }
            else
            {
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
        
        for newContact in newContacts
        {
            for contact in contacts
            {
                if contact.updatedWithDetailsFromContact(newContact)
                {
                    count++
                }
            }
        }
        print(contacts)
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
