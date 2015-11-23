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
		static let accessExpiresInSeconds	= "expires_in"
		static let accessToken				= "access_token"
		static let password					= "password"
		
		private init() { }
	}
	
    //
    // MARK: - Instance Methods
    //
	
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
	
    func isTheSameAsUser(other: User) -> Bool
    {
        return self.id == other.id
    }
	
    func updatedWithDetailsFromUser(other: User) -> Bool
    {
        if self.isTheSameAsUser(other)
        {
			if other.updatedOn!.timeIntervalSinceDate(self.updatedOn!) > 0
            {
                return save(other)
            }
            else
            {
                // TODO: - Make a POST request to push self to server
				// No public PUT API for user yet. Wait for that.
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

//
// MARK: - Quickbird API Methods
//

extension HiveService
{
	func didUpdateUser(user: User, fromJSON: JSON?) -> Bool
	{
		guard let json = fromJSON else
		{
			print("HiveService.didUpdateUser(_: fromJSON: ) - Response JSON is nil. User not updated.")
			return false
		}
		
		user.firstName			= json[User.Key.firstName].stringValue
		user.lastName			= json[User.Key.lastName].stringValue
		user.phone				= json[User.Key.phone].doubleValue
		user.id					= json[User.Key.id].intValue
		user.version				= json[User.Key.version].stringValue
		user.markedDeleted		= json[User.Key.markedDeleted].boolValue
		let updateDateString		= json[User.Key.updatedOn].stringValue
		user.updatedOn			= self.dateFormatter.dateFromString(updateDateString)
		let creationDateString	= json[User.Key.createdOn].stringValue
		user.createdOn			= self.dateFormatter.dateFromString(creationDateString)
		
		return true
	}
	
	func signupUser(user: User, completion: (didSignup: Bool, newUser: User?, error: String?)  -> Void)
	{
		let requestBody: NSDictionary? = [
			User.Key.firstName	: user.firstName!,
			User.Key.lastName	: user.lastName!,
			User.Key.phone		: "\(user.phone!)",
			User.Key.password	: user.passcode!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: requestBody, request: API.CreateUser.httpRequest(), token: nil)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				var details: String?
				if error!.rawValue == 101 {
					details = "\(user.phone!)"
				}
				else {
					details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				}
				print("⋮")
				print("⋮  ✗  User registration failed. \(error!.describe(details!))")
				completion(didSignup: false, newUser: nil, error: error!.describe(details!))
				return
			}
			
			if self.didUpdateUser(user, fromJSON: response) {
				completion(didSignup: true, newUser: user, error: nil)
			}
			else {
				completion(didSignup: true, newUser: nil, error: "Server sent a blank JSON response.")
			}
		}
	}
	
	func renewAccessTokenForUser(user: User, completion: (didRenew: Bool, newToken: String?, tokenExpiryDate: NSDate?, error: String?)  -> Void)
	{
		let phoneString = String(user.phone!)
		let username = phoneString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
		let password = user.passcode!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
		let body = "grant_type=password&username=\(username!)&password=\(password!)"
		
		let networkConnection = NetworkService(bodyAsPercentEncodedString: body, request: API.RequestToken.httpRequest(), token: nil)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				var details: String!
				if error!.rawValue != 103 {
					details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
					print("⋮")
					print("⋮  ✗  Login/token renewal failed. \(error!.describe(details))\n")
				}
				completion(didRenew: false, newToken: nil, tokenExpiryDate: nil, error: error!.describe(details))
				return
			}
			
			guard let token = response?[User.Key.accessToken].stringValue,
				  let expiresIn = response?[User.Key.accessExpiresInSeconds].doubleValue else
			{
				print("⋮")
				print("⋮  ✗  Invalid token.")
				completion(didRenew: false, newToken: nil, tokenExpiryDate: nil, error: "Invalid token.")
				return
			}
				
			let expiryDate = NSDate(timeIntervalSinceNow: expiresIn)
			print("⋮   ⋮    Token expires : \(expiryDate)\n")
			print("⋮")
			print("⋮  ✓  User login successful.")
			completion(didRenew: true, newToken: token, tokenExpiryDate: expiryDate, error: nil)
		}
	}
	
	func getUser(user: User, completion: (didGet: Bool, user: User?, error: String?) -> Void)
	{
		if user.accessToken == nil
		{
			self.renewAccessTokenForUser(user) {
				(renewed, token, expiryDate, error) in
				if renewed {
					user.accessToken = token
					user.accessExpiresOn = expiryDate
				}
				else {
					print("HiveService.getAccountDetails(_: completion: ) - User token is invalid and token renewal failed. ")
					return
				}
			}
		}
		
		let networkConnection = NetworkService(request: API.ReadUser.httpRequest(), token: user.accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				print("⋮  getAccountDetails: request failed. \(error!.describe(details))")
				completion(didGet: false, user: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateUser(user, fromJSON: response) {
				completion(didGet: true, user: user, error: nil)
			}
			else {
				completion(didGet: true, user: nil, error: "Server sent an empty JSON response.")
			}
		}
	}
	
	func sendSMSCodeToUser(user: User, completion: (didSend: Bool, error: String?) -> Void)
	{
		let body: NSDictionary? = [
			User.Key.lastName	: "\(user.lastName!)",
			User.Key.phone		: "\(user.phone!)"
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body!, request: API.RequestSMSCode.httpRequest(), token: nil)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				print("⋮  ✗  We couldn't send the code. HTTP Response code \(error!.describe(details))\n")
				completion(didSend: false, error: error!.describe(details))
				return
			}
			
			print("\n⋮  ✓  Code sent successfully.\n")
			completion(didSend: true, error: nil)
		}
	}
	
	///  The following APIs will be deprecated in favor of a unified updateUser API.
	///  Do not implement them. Here only for historical reasons. As soon as updateUser API is up
	///  nuke this from the orbit.
	
	func changePassword(accessToken token: String?, oldPassword: String, newPassword: String, completion: (didChange: Bool, error: String?) -> Void)
	{
		let body: NSDictionary? = [
			"OldPassword": oldPassword,
			"NewPassword": newPassword,
			"ConfirmPassword": newPassword
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.ChangePassword.httpRequest(), token: token)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				print("Password change failed. \(error!.describe(details))")
				completion(didChange: false, error: error!.describe(details))
				return
			}
			
			print("\n⋮  ✓  Password changed successfully.\n")
			completion(didChange: true, error: nil)
		}
	}
	
	func changePhone(accessToken token: String?, phone: NSNumber, completion: (didChange: Bool, error: String?) -> Void)
	{
		let body: NSDictionary? = [
			"PhoneNumber": phone.integerValue
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.ChangePhone.httpRequest(), token: token)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				print("Phone number couldn't be changed. \(error!.describe(details))")
				completion(didChange: false, error: error!.describe(details))
				return
			}
			
			print("\n⋮  ✓  Phone number changed successfully.\n")
			completion(didChange: true, error: nil)
		}
	}
	
	func changeEmail(accessToken token: String?, email: String, completion: (didChange: Bool, error: String?) -> Void)
	{
		let body: NSDictionary? = [
			"Email": email
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.ChangeEmail.httpRequest(), token: token)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				print("Email couldn't be changed. \(error!.describe(details))")
				completion(didChange: false, error: error!.describe(details))
				return
			}
			
			print("\n⋮  ✓  Change email successfully.\n")
			completion(didChange: true, error: nil)
		}
	}
}
