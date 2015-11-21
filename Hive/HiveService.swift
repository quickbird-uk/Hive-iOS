//
//  HiveService.swift
//  Hive
//
//  Created by Animesh. on 08/09/2015.
//  Copyright © 2015 Quickbird. All rights reserved.
//

import Foundation
import CoreData

class HiveService
{
    // Singleton
    static let shared = HiveService()
    
    // Restrict others from instantiating HiveService
    private init()
    {
        self.applicationKey = "defaultApplicationKey"
        self.apiBaseURL = NSURL(string: "https://api.quickbird.uk/")!
		self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSxxx"
		self.dateFormatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
		self.dateFormatter.locale = NSLocale(localeIdentifier: "en_GB")
    }
    
    //
    // MARK: - Properties
    //
    
    var applicationKey: String!
    var apiBaseURL: NSURL!
	let dateFormatter = NSDateFormatter()
	let errorDescriptionKey = "error_description"
    
    //l    // MARK: - Methods
    //
    
    func downsync(user: User, completion: (error: String?) -> Void)
    {
    // Create a dispatch group to be notified when all requests finish
        let dispatchGroup = dispatch_group_create()
        
    // Get all user details
        dispatch_group_enter(dispatchGroup)
        self.getAccountDetails(user) {
            (remoteUser, error) -> Void in
            if error == nil
            {
                print("    ⋮  User downloaded from server?  -  \(user.updatedWithDetailsFromUser(remoteUser!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
                print("    ⋮  User couldn't be synced.")
                dispatch_group_leave(dispatchGroup)
            }
        }
        
    // Get all contacts for user
        dispatch_group_enter(dispatchGroup)
        self.getAllContacts(accessToken: user.accessToken!) {
            (contacts, error) in
            if error == nil && contacts != nil
            {
                print("    ⋮  Contacts synced with server  -  \(Contact.updateAllContacts(contacts!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
                dispatch_group_leave(dispatchGroup)
            }
        }
		
    // Get all farms for user
        dispatch_group_enter(dispatchGroup)
        self.getAllOrganisations(accessToken: user.accessToken!) {
            (orgs, error) in
            if error == nil && orgs != nil
            {
                print("    ⋮  Organisations synced with server  -  \(Organisation.updateAllOrganisations(orgs!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
                dispatch_group_leave(dispatchGroup)
            }
        }
        
    // Get all tasks for user
        dispatch_group_enter(dispatchGroup)
        self.getAllTasks(accessToken: user.accessToken!) {
            (tasks, error) in
            if error == nil && tasks != nil
            {
                print("    ⋮  Tasks synced with server  -  \(Task.updateAllTasks(tasks!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
                dispatch_group_leave(dispatchGroup)
            }
        }
        
    // Get all fields for user
        dispatch_group_enter(dispatchGroup)
        self.getAllFields(accessToken: user.accessToken!) {
            (fields, error) in
            if error == nil && fields != nil
            {
                print("    ⋮  Fields synced with server  -  \(Field.updateAllFields(fields!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
                dispatch_group_leave(dispatchGroup)
            }
        }
        
    // Get all staff for user
        dispatch_group_enter(dispatchGroup)
        self.getAllStaff(accessToken: user.accessToken!) {
            (staffs, error) in
            if error == nil && staffs != nil
            {
                print("    ⋮  Staff synced with server  -  \(Staff.updateAllStaff(staffs!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
                dispatch_group_leave(dispatchGroup)
            }
        }
		
        // this block will be called async only when the above are done
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
            print("Sync complete.")
            completion (error: nil)
        }
    }
    
    //
    // MARK: - Account CRUD
    //
    
    func signup(user: User, completion: (user: User?, error: String?)  -> Void)
    {
    // Prepare the body
        let requestBody: NSDictionary? = [
            User.Key.firstName	: user.firstName!,
            User.Key.lastName	: user.lastName!,
            User.Key.phone		: "\(user.phone!)",
            User.Key.password	: user.passcode!
        ]
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: requestBody, request: API.CreateUser.httpRequest(), token: nil)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil
            {
                print("\n⋮  ✓  User registration successful. Requesting access token...\n")
                completion(user: user, error: nil)
            }
                
        // Request unsuccessful
            else
            {
                var details: String?
                if error!.rawValue == 101 {
                    details = "\(user.phone!)"
                }
                else {
                    details = response?[self.errorDescriptionKey].string
                }
                print("⋮")
                print("⋮  ✗  User registration failed. \(error!.describe(details!))")
                completion(user: nil, error: error!.describe(details!))
            }
        }
    }
    
    func renewAccessToken(user: User, completion: (token: String?, expiryDate: NSDate?, error: String?)  -> Void)
    {
    // Prepare request body
        let phoneString = String(user.phone!)
        let username = phoneString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        let password = user.passcode!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        let body = "grant_type=password&username=\(username!)&password=\(password!)"
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsPercentEncodedString: body, request: API.RequestToken.httpRequest(), token: nil)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil
            {
                guard let token = response?[User.Key.accessToken].string, let expiresIn = response?[User.Key.accessExpiresInSeconds].double else
                {
                    print("⋮")
                    print("⋮  ✗  Invalid token.")
                    completion(token: nil, expiryDate: nil, error: "Invalid token.")
                    // Get out of the scope
                    return
                }
                
                let expiryDate = NSDate(timeIntervalSinceNow: expiresIn)
                print("⋮   ⋮    Token expires : \(expiryDate)\n")
                print("⋮")
                print("⋮  ✓  User login successful.")
                completion(token: token, expiryDate: expiryDate, error: nil)
            }
                
        // Request Unsuccessful
            else
            {
                var details: String?
                if error!.rawValue != 103 {
                    details = response?[self.errorDescriptionKey].stringValue
					print("⋮")
					print("⋮  ✗  Login/token renewal failed. \(error!.describe(details!))\n")
                }
				
                completion(token: nil, expiryDate: nil, error: error!.describe(details ?? "Something bad happened."))
            }
        }
    }
    
    func getAccountDetails(user: User, completion: (user: User?, error: String?) -> Void)
    {
    // Check access token
        if user.accessToken == nil
        {
            self.renewAccessToken(user) {
                (token, expiryDate, error) in
                user.accessToken = token
                user.accessExpiresOn = expiryDate
            }
        }
        
    // Setup a network connection
        let networkConnection = NetworkService(request: API.ReadUser.httpRequest(), token: user.accessToken)
            
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
        // Request successful
            if error == nil
            {
                user.firstName		= response![User.Key.firstName].string
                user.lastName		= response![User.Key.lastName].string
                user.phone			= response![User.Key.phone].double
                user.id				= response![User.Key.id].int
                user.version			= response![User.Key.version].string
                user.markedDeleted	= response![User.Key.markedDeleted].bool
                let updateDateString = response![User.Key.updatedOn].string
                user.updatedOn = self.dateFormatter.dateFromString(updateDateString!)
                let creationDateString = response![User.Key.createdOn].string
                user.createdOn = self.dateFormatter.dateFromString(creationDateString!)
                
                
                print("⋮   ⋮    First name      - \(user.firstName)")
                print("⋮   ⋮    Last name       - \(user.lastName)")
                print("⋮   ⋮    Phone           - \(user.phone)\n")
                print("⋮   ⋮    Created         - \(user.createdOn)\n")
                print("⋮   ⋮    Updated         - \(user.updatedOn)\n")
                
                completion(user: user, error: nil)
            }
        
        // Request unsuccessful
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("⋮  getAccountDetails: request failed. \(error!.describe(details!))")
                completion(user: nil, error: error!.describe(details!))
            }
        }
    }
    
    func requestSMSCode(user: User, completion: (smsSent: Bool, error: String?) -> Void)
    {
    // Prepare request body
        let body: NSDictionary? = [
            User.Key.lastName	: "\(user.lastName!)",
            User.Key.phone		: "\(user.phone!)"
        ]
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body!, request: API.RequestSMSCode.httpRequest(), token: nil)

    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil
            {
                print("⋮")
                print("⋮  ✓  Code sent successfully.\n")
                completion(smsSent: true, error: nil)
            }
            
        // Request unsuccessful
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("⋮  ✗  We couldn't send the code. HTTP Response code \(error!.describe(details!))\n")
                completion(smsSent: false, error: error!.describe(details!))
            }
        }
    }
    
    func changePassword(accessToken token: String?, oldPassword: String, newPassword: String, completion: (passwordChanged: Bool, error: String?) -> Void)
    {
    // Prepare request body
        let body: NSDictionary? = [
            "OldPassword": oldPassword,
            "NewPassword": newPassword,
            "ConfirmPassword": newPassword
        ]
		
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.ChangePassword.httpRequest(), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request Successful
            if error == nil
            {
                print("Password changed successfully.")
                completion(passwordChanged: true, error: nil)
            }
                
        // Request Failed
            else {
                let details = response?[self.errorDescriptionKey].string
                print("Password change failed. \(error!.describe(details!))")
                completion(passwordChanged: false, error: error!.describe(details!))
            }
        }
    }
    
    func changePhone(accessToken token: String?, phone: NSNumber, completion: (phoneChanged: Bool, error: String?) -> Void)
    {
    // Prepare request body
        let body: NSDictionary? = [
            "PhoneNumber": phone.integerValue
        ]

    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.ChangePhone.httpRequest(), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request Successful
            if error == nil
            {
                print("Phone number changed successfully.")
                completion(phoneChanged: true, error: nil)
            }
                
        // Request failed
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("Phone number couldn't be changed. \(error!.describe(details!))")
                completion(phoneChanged: false, error: error!.describe(details!))
            }
        }
    }
    
    func changeEmail(accessToken token: String?, email: String, completion: (emailChanged: Bool, error: String?) -> Void)
    {
    // Prepare request body
        let body: NSDictionary? = [
            "Email": email
        ]
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.ChangeEmail.httpRequest(), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
        
        // Request Successful
            if error == nil
            {
                print("Email changed successfully.")
                completion(emailChanged: true, error: nil)
            }
            
        // Request Failed
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("Email couldn't be changed. \(error!.describe(details!))")
                completion(emailChanged: false, error: error!.describe(details!))
            }
        }
    }
    
    //
    // MARK: - Contacts CRUD
    //
    
    func getAllContacts(accessToken token: String, completion: (contacts: [Contact]?, error: String?) -> Void)
    {
    // Setup a network connection
        let networkConnection = NetworkService(request: API.ReadContacts.httpRequest(), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil && response != nil
            {
                var contacts = [Contact]()
                for info in response!
                {
                    let contactCard = info.1
                    let contact = NSEntityDescription.insertNewObjectForEntityForName(Contact.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Contact
                    
                    contact.firstName       = contactCard[Contact.Key.firstName].string
                    contact.lastName        = contactCard[Contact.Key.lastName].string
                    contact.phone           = contactCard[Contact.Key.phone].number
                    contact.friendID        = contactCard[Contact.Key.friendID].number
                    contact.id              = contactCard[Contact.Key.id].numberValue
                    contact.state           = contactCard[Contact.Key.state].string
                    contact.markedDeleted   = contactCard[Contact.Key.markedDeleted].bool
                    contact.version         = contactCard[Contact.Key.version].string
                    
                    
                    let updateDateString    = contactCard[Contact.Key.updatedOn].stringValue
                    contact.updatedOn       = self.dateFormatter.dateFromString(updateDateString)
                    let creationDateString  = contactCard[Contact.Key.createdOn].stringValue
                    contact.createdOn       = self.dateFormatter.dateFromString(creationDateString)
                    
                    contacts.append(contact)
                }
                // Callback
                completion(contacts: contacts, error: nil)
            }
                
                // Request unsuccessful
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("getAllContacts: request failed. \(error!.describe(details!))")
                completion(contacts: nil, error: error!.describe(details!))
            }
        }
    }
    
    func findContacts(accessToken token: String, phoneNumbers: [NSNumber], completion:(contacts: [Contact]?, error: String?) -> Void)
    {
        // Preparing request body
        let body = String(phoneNumbers)
        
        // Setup a network connection
        let networkConnection = NetworkService(bodyAsPercentEncodedString: body, request: API.FindContacts.httpRequest(), token: token)
        
        // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
            // Request successful
            if error == nil
            {
				var contacts = [Contact]()
                for contact in response!
                {
                    let contactCard = contact.1
                    let newContact = Contact.temporary()
					
                    newContact.firstName			= contactCard[Contact.Key.firstName].string
                    newContact.lastName			= contactCard[Contact.Key.lastName].string
                    newContact.phone				= contactCard[Contact.Key.phone].number
                    newContact.friendID			= contactCard[Contact.Key.friendID].number
                    newContact.id				= contactCard[Contact.Key.id].intValue
                    newContact.state				= contactCard[Contact.Key.state].string
                    newContact.markedDeleted		= contactCard[Contact.Key.markedDeleted].bool
                    newContact.version			= contactCard[Contact.Key.version].string
                    contacts.append(newContact)
                }
                completion(contacts: contacts, error: nil)
            }
                
                // Request unsuccessful
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("findContacts: request failed. \(error!.describe(details!))")
                completion(contacts: nil, error: error!.describe(details!))
            }
        }
    }
    
    func addContact(accessToken token: String, contactID: Int, completion: (requestSent: Bool, error: String?) -> Void)
    {
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsPercentEncodedString: "\(contactID)", request: API.CreateContact.httpRequest(), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request Successful
            if error == nil
            {
                print("Invite sent successfully.")
                completion(requestSent: true, error: nil)
            }
                
        // Request Failed
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("Invite couldn't be sent. \(error!.describe(details!))")
                completion(requestSent: false, error: error!.describe(details!))
            }
        }
    }
    
    func editContact(accessToken token: String, contact: Contact, completion: (detailsChanged: Bool, error: String?) -> Void)
    {
    // Prepare request body
        let body: NSDictionary? = [
            Contact.Key.friendID  : contact.friendID!,
            Contact.Key.state     : contact.state!,
            Contact.Key.firstName : contact.firstName!,
            Contact.Key.lastName  : contact.lastName!,
            Contact.Key.phone     : contact.phone!,
            Contact.Key.id		  : contact.id!
        ]
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateContact.httpRequest(urlParameter: "/\(contact.id!)"), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil
            {
                completion(detailsChanged: true, error: nil)
            }
                
        // Request unsuccessful
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("editContact: request failed. \(error!.describe(details!))")
                completion(detailsChanged: false, error: error!.describe(details!))
            }
        }
    }
    
    func deleteContact(accessToken token: String, connectionID: NSNumber?, completion: (deleted: Bool, error: String?) -> Void)
    {
    // Setup a network connection
        let networkConnection = NetworkService(request: API.DeleteContact.httpRequest(urlParameter: "/\(connectionID!)"), token: token)
        
    // Make the request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil
            {
                completion(deleted: true, error: nil)
            }
            
        // Request failed
            else
            {
                let details = response?[self.errorDescriptionKey].string
                print("deleteContact(_, completion: _) failed. \(error!.describe(details!))")
                completion(deleted: false, error: error!.describe(details!))
            }
        }
    }
    
    //
    // MARK: - Organisations CRUD
    //
    
    func getAllOrganisations(accessToken token: String, completion: (orgs: [Organisation]?, error: String?) -> Void)
    {
    // Setup a network connection
        let networkConnection = NetworkService(request: API.ReadOrganisation.httpRequest(), token: token)
    
    // Make the network request
        networkConnection.makeHTTPRequest {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("getAllOrganisations: request failed. \(error!.describe(details!))")
                completion(orgs: nil, error: error!.describe(details!))
                return
            }
            
        // Request successful
            var organisations = [Organisation]()
            for info in response!
            {
                let orgInfo = info.1
                let organisation            = Organisation.temporary()
				
                organisation.name           = orgInfo[Organisation.Key.name].string
                organisation.orgDescription = orgInfo[Organisation.Key.orgDescription].string
                organisation.role           = orgInfo[Organisation.Key.role].string
                organisation.id             = orgInfo[Organisation.Key.id].int
                organisation.markedDeleted  = orgInfo[Organisation.Key.markedDeleted].bool
                organisation.version        = orgInfo[Organisation.Key.version].string
				
				let createdString = orgInfo[Organisation.Key.createdOn].stringValue
				organisation.createdOn = self.dateFormatter.dateFromString(createdString)
				let updatedString = orgInfo[Organisation.Key.updatedOn].stringValue
				organisation.updatedOn = self.dateFormatter.dateFromString(updatedString)
                
                organisations.append(organisation)
            }
            
        // Callback
            completion(orgs: organisations, error: nil)
        }
    }
    
	func addOrganisation(accessToken token: String, organisation: Organisation, completion: (added: Bool, newOrg: Organisation?, error: String?) -> Void)
    {
    // Prepare request body
        let body: NSDictionary = [
            Organisation.Key.name			: organisation.name!,
            Organisation.Key.orgDescription : organisation.orgDescription!
		]
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateOrganisation.httpRequest(), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("getAllOrganisations: request failed. \(error!.describe(details!))")
				completion(added: false, newOrg: nil, error: error!.describe(details!))
                return
            }
            
        // Request succeeded
			organisation.id = response![Organisation.Key.id].numberValue
			organisation.role = response![Organisation.Key.role].stringValue
            completion(added: true, newOrg: organisation, error: nil)
        }
    }
    
    func editOrganisation(accessToken token: String, newOrg: Organisation, completion: (edited: Bool, error: String?) -> Void)
    {
    // Prepare request body
        let body: NSDictionary = [
            Organisation.Key.name           : newOrg.name!,
            Organisation.Key.orgDescription : newOrg.orgDescription!,
            Organisation.Key.role			: newOrg.role!,
            Organisation.Key.id             : newOrg.id!.integerValue,
            Organisation.Key.markedDeleted	: newOrg.markedDeleted!.boolValue
        ]
        
    // Setup the network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateOrganisation.httpRequest(urlParameter: "\(newOrg.id!.integerValue)"), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("editOrganisation: request failed. \(error!.describe(details!))")
                completion(edited: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(edited: true, error: nil)
        }
    }
    
    func deleteOrganisation(accessToken token: String, orgID: Int, completion: (deleted: Bool, error: String?) -> Void)
    {
        let networkConnection = NetworkService(request: API.DeleteOrganisation.httpRequest(urlParameter: "\(orgID)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("deleteOrganisation: request failed. \(error!.describe(details!))")
                completion(deleted: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(deleted: true, error: nil)
        }
    }
    
    //
    // MARK: - Tasks CRUD
    //
    
    func getAllTasks(accessToken token: String, completion: (tasks: [Task]?, error: String?) -> Void)
    {
        let networkConnection = NetworkService(request: API.ReadTasks.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("getAllTasks: request failed. \(error!.describe(details!))")
                completion(tasks: nil, error: error!.describe(details!))
                return
            }
            
        // Request successful
            var tasks = [Task]()
            for info in response!
            {
                let taskInfo = info.1
                let task = Task.temporary()
                
                task.name               = taskInfo[Task.Key.name].stringValue
                task.taskDescription    = taskInfo[Task.Key.taskDescription].stringValue
                task.type               = taskInfo[Task.Key.type].stringValue
                task.forFieldID         = taskInfo[Task.Key.forFieldID].intValue
                task.assignedByID       = taskInfo[Task.Key.assignedByID].intValue
                task.assignedToID       = taskInfo[Task.Key.assignedToID].intValue
                let dueDateString       = taskInfo[Task.Key.dueDate].stringValue
                task.dueDate            = self.dateFormatter.dateFromString(dueDateString)
                let finishDateString    = taskInfo[Task.Key.completedOnDate].stringValue
                task.completedOnDate    = self.dateFormatter.dateFromString(finishDateString)
				task.timeTaken			= taskInfo[Task.Key.timeTaken].doubleValue
                task.state              = taskInfo[Task.Key.state].stringValue
                task.payRate            = taskInfo[Task.Key.payRate].numberValue
                task.id                 = taskInfo[Task.Key.id].intValue
                let createdOnString     = taskInfo[Task.Key.createdOn].stringValue
                task.createdOn          = self.dateFormatter.dateFromString(createdOnString)
                let updatedOnString     = taskInfo[Task.Key.updatedOn].stringValue
                task.updatedOn          = self.dateFormatter.dateFromString(updatedOnString)
                task.version            = taskInfo[Task.Key.version].stringValue
                task.markedDeleted      = taskInfo[Task.Key.markedDeleted].boolValue
                
                tasks.append(task)
            }
            
        // Callback
            completion(tasks: tasks, error: nil)
        }
    }
    
	func addTask(accessToken token: String, newTask: Task, completion: (added: Bool, task: Task?, error: String?) -> Void)
    {
        let body: NSDictionary = [
            Task.Key.name				: newTask.name!,
            Task.Key.taskDescription		: newTask.taskDescription!,
            Task.Key.type				: newTask.type!,
			Task.Key.state				: newTask.state!,
            Task.Key.forFieldID			: newTask.forFieldID!.integerValue,
            Task.Key.assignedByID		: newTask.assignedByID!.integerValue,
            Task.Key.assignedToID		: newTask.assignedToID!.integerValue,
            Task.Key.dueDate				: "\(newTask.dueDate!)",
            Task.Key.payRate				: 2.20
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateTask.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil, let json = response else
            {
                let details = response?[self.errorDescriptionKey].string
                print("addTask: request failed. \(error!.describe(details!))")
				completion(added: false, task: nil, error: error!.describe(details!))
                return
            }
            
        // Request successful
			
			newTask.name					= json[Task.Key.name].stringValue
			newTask.taskDescription		= json[Task.Key.taskDescription].stringValue
			newTask.type					= json[Task.Key.type].stringValue
			newTask.forFieldID			= json[Task.Key.forFieldID].intValue
			newTask.assignedByID			= json[Task.Key.assignedByID].intValue
			newTask.assignedToID			= json[Task.Key.assignedToID].intValue
			let dueDateString			= json[Task.Key.dueDate].stringValue
			newTask.dueDate				= self.dateFormatter.dateFromString(dueDateString)
			let finishDateString			= json[Task.Key.completedOnDate].stringValue
			newTask.completedOnDate		= self.dateFormatter.dateFromString(finishDateString)
			newTask.timeTaken			= json[Task.Key.timeTaken].doubleValue
			newTask.state				= json[Task.Key.state].stringValue
			newTask.payRate				= json[Task.Key.payRate].numberValue
			newTask.id					= json[Task.Key.id].intValue
			let createdOnString			= json[Task.Key.createdOn].stringValue
			newTask.createdOn			= self.dateFormatter.dateFromString(createdOnString)
			let updatedOnString			= json[Task.Key.updatedOn].stringValue
			newTask.updatedOn			= self.dateFormatter.dateFromString(updatedOnString)
			newTask.version				= json[Task.Key.version].stringValue
			newTask.markedDeleted		= json[Task.Key.markedDeleted].boolValue
			
			completion(added: true, task: newTask, error: nil)
        }
    }
	
    func editTask(accessToken token: String, newTask: Task, completion: (edited: Bool, error: String?) -> Void)
    {
        print("Editing task...")
		
        let body: NSDictionary = [
            Task.Key.name             : newTask.name!,
            Task.Key.taskDescription  : newTask.taskDescription!,
            Task.Key.type             : newTask.type!,
            Task.Key.forFieldID       : newTask.forFieldID!.integerValue,
            Task.Key.assignedByID     : newTask.assignedByID!.integerValue,
            Task.Key.assignedToID     : newTask.assignedToID!.integerValue,
			Task.Key.timeTaken		  : newTask.timeTaken!.doubleValue,
            Task.Key.completedOnDate  : "\(newTask.completedOnDate!)",
            Task.Key.dueDate          : "\(newTask.dueDate!)",
            Task.Key.state            : newTask.state!,
            Task.Key.payRate          : newTask.payRate!
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateTask.httpRequest(urlParameter: "\(newTask.id!.integerValue)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("editTask: request failed. \(error!.describe(details!))")
                completion(edited: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(edited: true, error: nil)
        }
    }
    
    func deleteTask(accessToken token: String, taskID: Int, completion: (deleted: Bool, error: String?) -> Void)
    {
        print("Deleting task...")
        
        let networkConnection = NetworkService(request: API.DeleteTask.httpRequest(urlParameter: "\(taskID)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("deleteTask: request failed. \(error!.describe(details!))")
                completion(deleted: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(deleted: true, error: nil)
        }
    }
    
    //
    // MARK: - Fields CRUD
    //
    
    func getAllFields(accessToken token: String, completion: (fields: [Field]?, error: String?) -> Void)
    {
        print("Getting all fields...")
        
        let networkConnection = NetworkService(request: API.ReadField.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("getAllFields: request failed. \(error!.describe(details!))")
                completion(fields: nil, error: error!.describe(details!))
                return
            }
            
        // Request successful
            var fields = [Field]()
            for info in response!
            {
                let fieldInfo = info.1
                let field = Field.temporary()
                
                field.name              = fieldInfo[Field.Key.name].stringValue
                field.areaInHectares    = fieldInfo[Field.Key.areaInHectares].numberValue
                field.fieldDescription  = fieldInfo[Field.Key.fieldDescription].stringValue
                field.onOrganisationID  = fieldInfo[Field.Key.onOrganisationID].numberValue
				field.latitude			= fieldInfo[Field.Key.latitude].numberValue
				field.longitude			= fieldInfo[Field.Key.longitude].numberValue
				print("field is on organisation id \(field.onOrganisationID)")
                field.id                = fieldInfo[Field.Key.id].numberValue
                let createdOnString     = fieldInfo[Field.Key.createdOn].stringValue
                field.createdOn         = self.dateFormatter.dateFromString(createdOnString)
                let updatedOnString     = fieldInfo[Field.Key.updatedOn].stringValue
                field.updatedOn         = self.dateFormatter.dateFromString(updatedOnString)
                field.version           = fieldInfo[Field.Key.version].stringValue
                field.markedDeleted     = fieldInfo[Field.Key.markedDeleted].boolValue
                
                fields.append(field)
            }
            
        // Callback
            completion(fields: fields, error: nil)
        }
    }
    
	func addField(accessToken token: String, newField: Field, completion: (added: Bool, newField: Field?, error: String?) -> Void)
    {
        print("Creating a field...")
        
        let body: NSDictionary = [
            Field.Key.name             : newField.name!,
            Field.Key.areaInHectares   : newField.areaInHectares!,
            Field.Key.fieldDescription : newField.fieldDescription!,
            Field.Key.onOrganisationID : newField.onOrganisationID!,
			Field.Key.latitude		   : newField.latitude!,
			Field.Key.longitude		   : newField.longitude!
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateField.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("createField: request failed. \(error!.describe(details!))")
                completion(added: false, newField: nil, error: error!.describe(details!))
                return
            }
            
        // Request successful
			newField.name              = response![Field.Key.name].stringValue
			newField.areaInHectares    = response![Field.Key.areaInHectares].numberValue
			newField.fieldDescription  = response![Field.Key.fieldDescription].stringValue
			newField.onOrganisationID  = response![Field.Key.onOrganisationID].numberValue
			newField.latitude			= response![Field.Key.latitude].numberValue
			newField.longitude			= response![Field.Key.longitude].numberValue
			print("field is on organisation id \(newField.onOrganisationID)")
			newField.id                = response![Field.Key.id].numberValue
			let createdOnString     = response![Field.Key.createdOn].stringValue
			newField.createdOn         = self.dateFormatter.dateFromString(createdOnString)
			let updatedOnString     = response![Field.Key.updatedOn].stringValue
			newField.updatedOn         = self.dateFormatter.dateFromString(updatedOnString)
			newField.version           = response![Field.Key.version].stringValue
			newField.markedDeleted     = response![Field.Key.markedDeleted].boolValue
			completion(added: true, newField: newField, error: nil)
        }
    }
	
    func editField(accessToken token: String, newField: Field, completion: (edited: Bool, error: String?) -> Void)
    {
        print("Editing field...")
        
        let body: NSDictionary = [
			Field.Key.name             : newField.name!,
			Field.Key.areaInHectares   : newField.areaInHectares!,
			Field.Key.fieldDescription : newField.fieldDescription!,
			Field.Key.onOrganisationID : newField.onOrganisationID!,
			Field.Key.latitude		   : newField.latitude!,
			Field.Key.longitude	       : newField.longitude!
        ]
		
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateField.httpRequest(urlParameter: "\(newField.id!.integerValue)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("editField: request failed. \(error!.describe(details!))")
                completion(edited: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(edited: true, error: nil)
        }
    }
    
    func deleteField(accessToken token: String, fieldID: Int, completion: (deleted: Bool, error: String?) -> Void)
    {
        print("Deleting field...")
        
        let networkConnection = NetworkService(request: API.DeleteField.httpRequest(urlParameter: "\(fieldID)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("deleteField: request failed. \(error!.describe(details!))")
                completion(deleted: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(deleted: true, error: nil)
        }
    }
    
    //
    // MARK: - Staff CRUD
    //
    
    func getAllStaff(accessToken token: String, completion: (staffs: [Staff]?, error: String?) -> Void)
    {
        print("Getting all staff...")
        
        let networkConnection = NetworkService(request: API.ReadStaff.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("createField: request failed. \(error!.describe(details!))")
                completion(staffs: nil, error: error!.describe(details!))
                return
            }
            
        // Request successful
            var staffs = [Staff]()
            for info in response!
            {
                let staffInfo = info.1
                let staff = Staff.temporary()
                
                staff.personID			= staffInfo[Staff.Key.personID].numberValue
                staff.onOrganisationID  = staffInfo[Staff.Key.onOrganisationID].numberValue
                staff.role				= staffInfo[Staff.Key.role].stringValue
                staff.firstName			= staffInfo[Staff.Key.firstName].stringValue
                staff.lastName			= staffInfo[Staff.Key.lastName].stringValue
                staff.phone				= staffInfo[Staff.Key.phone].numberValue
                staff.id					= staffInfo[Staff.Key.id].numberValue
                let createdOnString		= staffInfo[Staff.Key.createdOn].stringValue
                staff.createdOn			= self.dateFormatter.dateFromString(createdOnString)
                let updatedOnString		= staffInfo[Staff.Key.updatedOn].stringValue
                staff.updatedOn			= self.dateFormatter.dateFromString(updatedOnString)
                staff.version			= staffInfo[Staff.Key.version].stringValue
                staff.markedDeleted		= staffInfo[Staff.Key.markedDeleted].boolValue
				
				print("Updated on \(updatedOnString) \(staff.updatedOn)")
                staffs.append(staff)
            }
            
        // Callback
			print("Sending \(staffs.count) to local.")
            completion(staffs: staffs, error: nil)
        }
    }
    
    func addStaff(accessToken token: String, newStaff: Staff, completion: (added: Bool, error: String?) -> Void)
    {
        print("Adding staff...")
        
        let body: NSDictionary = [
            Staff.Key.personID          : newStaff.personID!,
            Staff.Key.onOrganisationID  : newStaff.onOrganisationID!,
            Staff.Key.role              : newStaff.role!
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateStaff.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("addStaff: request failed. \(error!.describe(details!))")
                completion(added: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(added: true, error: nil)
        }
    }
    
    func editStaff(accessToken token: String, newStaff: Staff, completion: (edited: Bool, error: String?) -> Void)
    {
        print("Editing staff....")
        
        let body: NSDictionary = [
			Staff.Key.personID          : newStaff.personID!,
			Staff.Key.onOrganisationID  : newStaff.onOrganisationID!,
			Staff.Key.role              : newStaff.role!,
			Staff.Key.firstName         : newStaff.firstName!,
			Staff.Key.lastName          : newStaff.lastName!,
			Staff.Key.phone             : newStaff.phone!
        ]
		
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateStaff.httpRequest(urlParameter: "\(newStaff.id!.integerValue)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("editStaff: request failed. \(error!.describe(details!))")
                completion(edited: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(edited: true, error: nil)
        }
    }
    
    func deleteStaff(accessToken token: String, staffID: Int, completion: (deleted: Bool, error: String?) -> Void)
    {
        print("Deleting staff...")
        
        let networkConnection = NetworkService(request: API.DeleteStaff.httpRequest(urlParameter: "\(staffID)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?[self.errorDescriptionKey].string
                print("deleteStaff: request failed. \(error!.describe(details!))")
                completion(deleted: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(deleted: true, error: nil)
        }
    }

    //
    // MARK: - API Handler
    //
    
    enum API
    {
    // Account
        case CreateUser
        case ReadUser
        case UpdateUser
        case DeleteUser
        case ChangeEmail
        case ChangePassword
        case ChangePhone
        case RequestSMSCode
        case RequestToken
        
    // Contacts
        case CreateContact
        case ReadContacts
        case UpdateContact
        case DeleteContact
        case FindContacts
        
    // Organisations
        case CreateOrganisation
        case ReadOrganisation
        case UpdateOrganisation
        case DeleteOrganisation
        
    // Fields
        case CreateField
        case ReadField
        case UpdateField
        case DeleteField
        
    // Staff
        case CreateStaff
        case ReadStaff
        case UpdateStaff
        case DeleteStaff
        
    // Tasks
        case CreateTask
        case ReadTasks
        case UpdateTask
        case DeleteTask
        
    // Get HTTP method for the call
        var httpMethod: HTTPMethod {
            switch self
            {
                case .CreateUser,
                     .RequestToken,
                     .RequestSMSCode,
                     .ChangePassword,
                     .ChangePhone,
                     .ChangeEmail,
                     .CreateContact,
                     .FindContacts,
                     .CreateOrganisation,
                     .CreateField,
                     .CreateStaff,
                     .CreateTask:
                     return .POST
                
                case .ReadUser,
                     .ReadContacts,
                     .ReadOrganisation,
                     .ReadField,
                     .ReadStaff,
                     .ReadTasks:
                     return .GET
                
                case .UpdateUser,
                     .UpdateContact,
                     .UpdateOrganisation,
                     .UpdateField,
                     .UpdateStaff,
                     .UpdateTask:
                     return .PUT
                
                case .DeleteUser,
                     .DeleteContact,
                     .DeleteOrganisation,
                     .DeleteField,
                     .DeleteStaff,
                     .DeleteTask:
                     return .DELETE
            }
        }
        
    // Get HTTP Content-Type header for the call
        var contentType: String {
            switch self {
            case .RequestToken:
                return "application/x-www-form-urlencoded"
            default:
                return "application/json"
            }
        }
        
    // Get request URL path
        var requestPath: String {
            switch self
            {
            // Account
                case .CreateUser:
                    return "Account/Register"
                case .ReadUser, .UpdateUser, .DeleteUser:
                    return "Account/UserInfo"
                case .ChangeEmail:
                    return "Account/ChangeEmail"
                case .ChangePassword:
                    return "Account/ChangePassword"
                case .ChangePhone:
                    return "Account/ChangePhone"
                case .RequestSMSCode:
                    return "Account/RequestSMSCode"
                
            // Contacts
                case .CreateContact, .ReadContacts, .UpdateContact, .DeleteContact:
                    return "Contacts"
                case .FindContacts:
                    return "Contacts/Search"
                
            // Organisation
                case .CreateOrganisation, .ReadOrganisation, .UpdateOrganisation, .DeleteOrganisation:
                    return "Organisations"
            
            // Fields
                case .CreateField, .ReadField, .UpdateField, .DeleteField:
                    return "Fields"
                
            // Staff
                case .CreateStaff, .ReadStaff, .UpdateStaff, .DeleteStaff:
                    return "Staff"
            
            // Tasks
                case .CreateTask, .ReadTasks, .UpdateTask, .DeleteTask:
                    return "Tasks"
                
            // Helper Methods
                case .RequestToken:
                    return "RequestToken"
            }
        }
        
    // Returns network request object
        func httpRequest(urlParameter parameter: String = "") -> NSMutableURLRequest
        {
            let path = NSURL(string: self.requestPath + parameter, relativeToURL: HiveService.shared.apiBaseURL)
            let request = NSMutableURLRequest(URL: path!)
            request.HTTPMethod = self.httpMethod.rawValue
            request.setValue(self.contentType, forHTTPHeaderField: "Content-Type")
            return request
        }
    }
    
    //
    // MARK: - Error Handler
    //
    
    enum Errors: Int
    {
    // Registration errors
        case PhoneAlreadyInUse      = 101
        case EmailAlreadyInUse      = 102
        case IncorrectLoginDetails  = 103
        case WeakPassword           = 104
        
    // Data errors
        case NotAuthorizedToView    = 201
        case NotAuthorizedToEdit    = 202
        case InvalidChanges         = 203
        case ItemNotFound           = 204
        case EmptyRequest           = 205
        case ModelError             = 206
        case ItemAlreadyExists      = 207
        case AccessLevelTooLow      = 208
        case NotContactOrStaff      = 209
        
    // System errors
        case AbuseWarning           = 700
        case UnhandledError         = 999
        
        func describe(details: String) -> String
        {
            switch self
            {
        // 1xx Errors
                case .PhoneAlreadyInUse:
                    return "An account with phone number " + details + " already exists."
                case .EmailAlreadyInUse:
                    return "An account with email " + details + " already exists."
                case .IncorrectLoginDetails:
                    return "Sorry, there is no account with these login credentials. Please check the details and try again."
                case .WeakPassword:
                    return "Your password is not strong enough. Passwords need to have a minimum of 8 characters."
                
        // 2xx Errors
                case .NotAuthorizedToView:
                    return "You don't have access to this information. Please ask your manager to adjust your role."
                case .NotAuthorizedToEdit:
                    return "You don't have privileges to edit this information. Please ask your manager to adjust your role."
                case .InvalidChanges:
                    return "Invalid changes: The changes couldn't be made."
                case .ItemNotFound:
                    return "\(details) couldn't be found."
                case .EmptyRequest:
                    return "Server recieved no data from the client."
                case .ModelError:
                    return details
                case .ItemAlreadyExists:
                    return "This " + details + " already exists."
                case .AccessLevelTooLow:
                    return "You don't have privileges to access this information. Please speak to your manager."
                case .NotContactOrStaff:
                    return "This person is not a contact or staff. You need to add them as contact/staff to proceed."
                
        // 7xx Errors
                case .AbuseWarning:
                    return "Your usage of the API is considered abusive. This usually happens when you send requests that are too large, or too frequent. Continue doing so at your peril!"
                
        // 9xx Errors
                case .UnhandledError:
                    return "Something bad happened. No clue what."
            }
        }
    }
}
























