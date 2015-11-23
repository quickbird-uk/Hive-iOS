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
    @NSManaged var areaInHectares: NSNumber?
    @NSManaged var fieldDescription: String?
    @NSManaged var id: NSNumber?
    @NSManaged var name: String?
	@NSManaged var latitude: NSNumber?
	@NSManaged var longitude: NSNumber?
    @NSManaged var onOrganisationID: NSNumber?
    @NSManaged var createdOn: NSDate?
    @NSManaged var updatedOn: NSDate?
    @NSManaged var version: String?
    @NSManaged var markedDeleted: NSNumber?

	//
	// MARK: - API Response JSON Keys
	//
	
	struct Key
	{
		static let id					= "id"
		static let areaInHectares		= "areaInHectares"
		static let fieldDescription		= "fieldDescription"
		static let name					= "name"
		static let latitude				= "latitude"
		static let longitude				= "longitude"
		static let onOrganisationID		= "onOrganisationID"
		static let createdOn				= "createdOn"
		static let updatedOn				= "updatedOn"
		static let version				= "version"
		static let markedDeleted			= "markedDeleted"
		
		private init() { }
	}
	
    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsField(other: Field) -> Bool
    {
        return self.id == other.id
    }
    
    private func save(newField: Field) -> Bool
    {
        id					= newField.id
        areaInHectares		= newField.areaInHectares
        fieldDescription		= newField.fieldDescription
        name					= newField.name
		latitude				= newField.latitude
		longitude			= newField.longitude
        onOrganisationID		= newField.onOrganisationID
        createdOn			= newField.createdOn
        updatedOn			= newField.updatedOn
        version				= newField.version
        markedDeleted		= newField.markedDeleted
        
        return Data.shared.saveContext(message: "Updated field with name \(self.name).")
    }
    
    func updatedWithDetailsFromField(other: Field) -> Bool
    {
        if self.isTheSameAsField(other)
        {
        // If `other` is more recent than `self`
			if other.updatedOn!.timeIntervalSinceDate(self.updatedOn!) > 0
            {
                return save(other)
            }
            else
            {
				let accessToken = User.get()!.accessToken!
				var updated = false
				HiveService.shared.updateField(self, accessToken: accessToken) {
					(didUpdate, updatedField, error) -> Void in
					if didUpdate && error == nil {
						updated = self.save(updatedField!)
					}
				}
                return updated
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
        let tempField = NSEntityDescription.insertNewObjectForEntityForName(Field.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Field
		tempField.createdOn = NSDate()
		tempField.updatedOn = NSDate()
		return tempField
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
			if result?.count > 0 {
				return result
			}
			else {
				return nil
			}
        }
        catch
        {
            print("Couldn't fetch any fields.")
            return nil
        }
    }
    
    class func updateAll(newFields: [Field]) -> Int
    {
        var count = 0
		var fieldToSync: Field!
		var matchFound = false
		
        guard let fields = Field.getAll() else
        {
            print("Local database has no fields. Adding new fields.")
            for newField in newFields
            {
                newField.moveToPersistentStore()
            }
            return newFields.count
        }
        
		for newField in newFields {
			for field in fields {
				if field.isTheSameAsField(newField) {
					matchFound = true
					fieldToSync = field
					break
				}
			}
			if matchFound {
				fieldToSync.updatedWithDetailsFromField(newField)
				count++
			}
			else {
				newField.moveToPersistentStore()
				count++
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

//
// MARK: - Quickbird API Methods
//

extension HiveService
{
	func didUpdateField(field: Field, fromJSON: JSON?) -> Bool
	{
		guard let json = fromJSON else
		{
			print("HiveService.didUpdateField(_: fromJSON: ) - Response JSON is nil.")
			return false
		}
		
		field.name				= json[Field.Key.name].stringValue
		field.areaInHectares		= json[Field.Key.areaInHectares].numberValue
		field.fieldDescription	= json[Field.Key.fieldDescription].stringValue
		field.onOrganisationID	= json[Field.Key.onOrganisationID].numberValue
		field.latitude			= json[Field.Key.latitude].numberValue
		field.longitude			= json[Field.Key.longitude].numberValue
		field.id					= json[Field.Key.id].numberValue
		let createdOnString		= json[Field.Key.createdOn].stringValue
		field.createdOn			= self.dateFormatter.dateFromString(createdOnString)
		let updatedOnString		= json[Field.Key.updatedOn].stringValue
		field.updatedOn			= self.dateFormatter.dateFromString(updatedOnString)
		field.version			= json[Field.Key.version].stringValue
		field.markedDeleted		= json[Field.Key.markedDeleted].boolValue
		
		return true
	}
	
	func getAllFields(accessToken token: String, completion: (didGet: Bool, fields: [Field]?, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.ReadField.httpRequest(), token: token)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didGet: false, fields: nil, error: error!.describe(details))
				return
			}
			
			guard let jsonArray = response else
			{
				completion(didGet: false, fields: nil, error: "Server response was empty.")
				return
			}
			
			var fields = [Field]()
			for info in jsonArray
			{
				let fieldInfo = info.1
				let field = Field.temporary()
				if self.didUpdateField(field, fromJSON: fieldInfo) {
					fields.append(field)
				}
			}
			
			completion(didGet: true, fields: fields, error: nil)
		}
	}
	
	func addField(field: Field, accessToken: String, completion: (didAdd: Bool, newField: Field?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Field.Key.name             : field.name!,
			Field.Key.areaInHectares   : field.areaInHectares!,
			Field.Key.fieldDescription : field.fieldDescription!,
			Field.Key.onOrganisationID : field.onOrganisationID!,
			Field.Key.latitude		   : field.latitude!,
			Field.Key.longitude		   : field.longitude!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateField.httpRequest(), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didAdd: false, newField: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateField(field, fromJSON: response) {
				completion(didAdd: true, newField: field, error: nil)
			}
			else {
				completion(didAdd: true, newField: nil, error: "Server response was empty. Sync your Hive now to stay up-to-date.")
			}
		}
	}
	
	func updateField(field: Field, accessToken: String, completion: (didUpdate: Bool, updatedField: Field?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Field.Key.name             : field.name!,
			Field.Key.areaInHectares   : field.areaInHectares!,
			Field.Key.fieldDescription : field.fieldDescription!,
			Field.Key.onOrganisationID : field.onOrganisationID!,
			Field.Key.latitude		   : field.latitude!,
			Field.Key.longitude	       : field.longitude!,
			Field.Key.id				   : field.id!,
			Field.Key.version		   : field.version!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateField.httpRequest(urlParameter: "/\(field.id!.integerValue)"), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didUpdate: false, updatedField: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateField(field, fromJSON: response) {
				completion(didUpdate: true, updatedField: field, error: nil)
			}
			else {
				completion(didUpdate: true, updatedField: nil, error: "Server response was empty. Sync your Hive now to stay up-to-date.")
			}
		}
	}
	
	func deleteFieldWithID(fieldID: Int, accessToken: String, completion: (didDelete: Bool, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.DeleteField.httpRequest(urlParameter: "/\(fieldID)"), token: accessToken)
		
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


