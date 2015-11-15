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
    }
    
    //
    // MARK: - Properties
    //
    
    var applicationKey: String!
    var apiBaseURL: NSURL!
    let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSxxx"
    
    //
    // MARK: - Methods
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
        print("Signing up...")
        
    // Prepare the body
        let requestBody: NSDictionary? = [
            "firstName": "\(user.firstName!)",
            "lastName" : "\(user.lastName!)",
            "phone"    : "\(user.phone!)",
            "password" : "\(user.passcode!)"
        ]
        print("\n⋮    \(requestBody!)\n")
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: requestBody, request: API.CreateUser.httpRequest(), token: nil)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil
            {
                print(response)
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
                    details = response?["error_description"].string
                }
                print("⋮")
                print("⋮  ✗  User registration failed. \(error!.describe(details!))")
                completion(user: nil, error: error!.describe(details!))
            }
        }
    }
    
    func renewAccessToken(user: User, completion: (token: String?, expiryDate: NSDate?, error: String?)  -> Void)
    {
        print("Logging in...")
    
    // Prepare request body
        let phoneString = String(user.phone!)
        let username = phoneString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        let password = user.passcode!.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        let body = "grant_type=password&username=\(username!)&password=\(password!)"
        print("⋮  BODY")
        print("⋮    \(body)\n")
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsPercentEncodedString: body, request: API.RequestToken.httpRequest(), token: nil)
        
    // Make the network request
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request successful
            if error == nil
            {
                guard let token = response?["access_token"].string, let expiresIn = response?["expires_in"].double else
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
                    details = response?["error_description"].stringValue
					print("⋮")
					print("⋮  ✗  Login/token renewal failed. \(error!.describe(details!))\n")
                }
				
                completion(token: nil, expiryDate: nil, error: error!.describe(details ?? "Something bad happened."))
            }
        }
    }
    
    func getAccountDetails(user: User, completion: (user: User?, error: String?) -> Void)
    {
        print("⋮  Downloading user account data...\n")
        
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
                user.firstName = response!["firstName"].string
                user.lastName = response!["lastName"].string
                user.phone = response!["phone"].double
                user.id = response!["Id"].int
                user.version = response!["Version"].string
                user.markedDeleted = response!["Deleted"].bool
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSxxx"
                let updateDateString = response!["UpdatedAt"].string
                user.updatedOn = dateFormatter.dateFromString(updateDateString!)
                let creationDateString = response!["CreatedAt"].string
                user.createdOn = dateFormatter.dateFromString(creationDateString!)
                
                
                print("⋮   ⋮    First name      - \(user.firstName)")
                print("⋮   ⋮    Last name       - \(user.lastName)")
                print("⋮   ⋮    Phone       - \(user.phone)\n")
                print("⋮   ⋮    Created       - \(user.createdOn)\n")
                print("⋮   ⋮    Updated       - \(user.updatedOn)\n")
                
                completion(user: user, error: nil)
            }
        
        // Request unsuccessful
            else
            {
                let details = response?["error_description"].string
                print("⋮  getAccountDetails: request failed. \(error!.describe(details!))")
                completion(user: nil, error: error!.describe(details!))
            }
        }
    }
    
    func requestSMSCode(user: User, completion: (smsSent: Bool, error: String?) -> Void)
    {
        print("⋮  Requesting SMS code...\n")
        
    // Prepare request body
        let body: NSDictionary? = [
            "lastName": "\(user.lastName!)",
            "phone"    : "\(user.phone!)"
        ]
        print("⋮  BODY")
        print("⋮    \(body!)\n")
        
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
                let details = response?["error_description"].string
                print("⋮  ✗  We couldn't send the code. HTTP Response code \(error!.describe(details!))\n")
                completion(smsSent: false, error: error!.describe(details!))
            }
        }
    }
    
    func changePassword(accessToken token: String?, oldPassword: String, newPassword: String, completion: (passwordChanged: Bool, error: String?) -> Void)
    {
        print("Changing password...")
        
    // Prepare request body
        let body: NSDictionary? = [
            "OldPassword": oldPassword,
            "NewPassword": newPassword,
            "ConfirmPassword": newPassword
        ]
        print("⋮  BODY")
        print("⋮    \(body!)\n")
        
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
                let details = response?["error_description"].string
                print("Password change failed. \(error!.describe(details!))")
                completion(passwordChanged: false, error: error!.describe(details!))
            }
        }
    }
    
    func changePhone(accessToken token: String?, phone: NSNumber, completion: (phoneChanged: Bool, error: String?) -> Void)
    {
        print("Changing phone number...")
        
    // Prepare request body
        let body: NSDictionary? = [
            "PhoneNumber": phone.integerValue
        ]
        print("⋮  BODY")
        print("⋮    \(body!)\n")
        
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
                let details = response?["error_description"].string
                print("Phone number couldn't be changed. \(error!.describe(details!))")
                completion(phoneChanged: false, error: error!.describe(details!))
            }
        }
    }
    
    func changeEmail(accessToken token: String?, email: String, completion: (emailChanged: Bool, error: String?) -> Void)
    {
        print("Changing email...")
        
    // Prepare request body
        let body: NSDictionary? = [
            "Email": email
        ]
        print("⋮  BODY")
        print("⋮    \(body!)\n")
        
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
                let details = response?["error_description"].string
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
        print("Getting contacts...")
        
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
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = self.dateFormat
                    
                    contact.firstName       = contactCard["firstName"].string
                    contact.lastName        = contactCard["lastName"].string
                    contact.phone           = contactCard["phone"].number
                    contact.personID        = contactCard["personID"].number
                    contact.id              = contactCard["Id"].numberValue
                    contact.state           = contactCard["state"].string
                    contact.markedDeleted   = contactCard["Deleted"].bool
                    contact.version         = contactCard["Version"].string
                    
                    
                    let updateDateString    = contactCard["UpdatedAt"].string
                    contact.updatedOn       = dateFormatter.dateFromString(updateDateString!)
                    let creationDateString  = contactCard["CreatedAt"].string
                    contact.createdOn       = dateFormatter.dateFromString(creationDateString!)
                    
                    contacts.append(contact)
                }
                // Callback
                completion(contacts: contacts, error: nil)
            }
                
                // Request unsuccessful
            else
            {
                let details = response?["error_description"].string
                print("getAllContacts: request failed. \(error!.describe(details!))")
                completion(contacts: nil, error: error!.describe(details!))
            }
        }
    }
    
    func findContacts(accessToken token: String, phoneNumbers: [NSNumber], completion:(contacts: [Contact]?, error: String?) -> Void)
    {
        print("Finding contacts...")
        
        // Preparing request body
        let body = String(phoneNumbers)
        print("⋮  BODY")
        print("⋮    \(body)\n")
        
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
                    newContact.firstName = contactCard["firstName"].string
                    newContact.lastName = contactCard["lastName"].string
                    newContact.phone = contactCard["phone"].number
                    newContact.personID = contactCard["personID"].number
                    newContact.id = contactCard["id"].numberValue
                    newContact.state = contactCard["state"].string
                    newContact.markedDeleted = contactCard["Deleted"].bool
                    newContact.version = contactCard["version"].string
                    contacts.append(newContact)
                }
                completion(contacts: contacts, error: nil)
            }
                
                // Request unsuccessful
            else
            {
                let details = response?["error_description"].string
                print("findContacts: request failed. \(error!.describe(details!))")
                completion(contacts: nil, error: error!.describe(details!))
            }
        }
    }
    
    func addContact(accessToken token: String, contactID: Int, completion: (requestSent: Bool, error: String?) -> Void)
    {
        print("Adding contact...")
    
    // Prepare request body
        let body: NSDictionary = [
            "recipientID": contactID
        ]
        print("⋮  BODY")
        print("⋮    \(body)\n")
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateContact.httpRequest(), token: token)
        
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
                let details = response?["error_description"].string
                print("Invite couldn't be sent. \(error!.describe(details!))")
                completion(requestSent: false, error: error!.describe(details!))
            }
        }
    }
    
    func editContact(accessToken token: String, contact: Contact, completion: (detailsChanged: Bool, error: String?) -> Void)
    {
        print("Editing contact... \(contact)")
        
    // Prepare request body
        let body: NSDictionary? = [
            "personID"  : contact.personID!,
            "state"     : contact.state!,
            "firstName" : contact.firstName!,
            "lastName"  : contact.lastName!,
            "phone"     : contact.phone!,
            "id"        : contact.id!
        ]
        print("⋮  BODY")
        print("⋮    \(body!)\n")
        
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
                let details = response?["error_description"].string
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
                let details = response?["error_description"].string
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
        print("Getting organisations...")
        
    // Setup a network connection
        let networkConnection = NetworkService(request: API.ReadOrganisation.httpRequest(), token: token)
    
    // Make the network request
        networkConnection.makeHTTPRequest {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
                
                organisation.name           = orgInfo["name"].string
                organisation.orgDescription = orgInfo["orgDescription"].string
                organisation.role           = orgInfo["role"].string
                organisation.id             = orgInfo["Id"].int
                organisation.markedDeleted  = orgInfo["Deleted"].bool
                organisation.version        = orgInfo["Version"].string
                
                organisations.append(organisation)
            }
            
        // Callback
            completion(orgs: organisations, error: nil)
        }
    }
    
    func addOrganisation(accessToken token: String, organisation: Organisation, completion: (added: Bool, error: String?) -> Void)
    {
        print("Adding organisation...")
        
    // Prepare request body
        let body: NSDictionary = [
            "name"              : organisation.name!,
            "orgDescription"    : organisation.orgDescription!,
            "role"              : organisation.role!
        ]
        
    // Setup a network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateOrganisation.httpRequest(), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
                print("getAllOrganisations: request failed. \(error!.describe(details!))")
                completion(added: false, error: error!.describe(details!))
                return
            }
            
        // Request succeeded
            completion(added: true, error: nil)
        }
    }
    
    func editOrganisation(accessToken token: String, newOrg: Organisation, completion: (edited: Bool, error: String?) -> Void)
    {
        print("Editing organisation...")
        
    // Prepare request body
        let body: NSDictionary = [
            "name"              : newOrg.name!,
            "orgDescription"    : newOrg.orgDescription!,
            "role"              : newOrg.role!,
            "Id"                : newOrg.id!.integerValue,
            "Deleted"           : newOrg.markedDeleted!.boolValue
        ]
        print("⋮  BODY")
        print("⋮    \(body)\n")
        
    // Setup the network connection
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateOrganisation.httpRequest(urlParameter: "\(newOrg.id!.integerValue)"), token: token)
        
    // Make the network request
        networkConnection.makeHTTPRequest {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
        print("Deleting organisation...")

        let networkConnection = NetworkService(request: API.DeleteOrganisation.httpRequest(urlParameter: "\(orgID)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
        print("Getting all tasks...")
        
        let networkConnection = NetworkService(request: API.ReadTasks.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = self.dateFormat
                
                task.name               = taskInfo["name"].stringValue
                task.taskDescription    = taskInfo["jobDescription"].stringValue
                task.type               = taskInfo["type"].stringValue
                task.forField           = taskInfo["onFieldId"].intValue
                task.assignedBy         = taskInfo["assignedById"].intValue
                task.assignedTo         = taskInfo["assignedToId"].intValue
                let dueDateString       = taskInfo["DueDate"].stringValue
                task.dueDate            = dateFormatter.dateFromString(dueDateString)
                let finishDateString    = taskInfo["DateFinished"].stringValue
                task.completedOnDate    = dateFormatter.dateFromString(finishDateString)
                task.state              = taskInfo["state"].stringValue
                task.payRate            = taskInfo["rate"].numberValue
                task.id                 = taskInfo["Id"].intValue
                let createdOnString     = taskInfo["CreatedAt"].stringValue
                task.createdOn          = dateFormatter.dateFromString(createdOnString)
                let updatedOnString     = taskInfo["UpdatedAt"].stringValue
                task.updatedOn          = dateFormatter.dateFromString(updatedOnString)
                task.version            = taskInfo["Version"].stringValue
                task.markedDeleted      = taskInfo["Deleted"].boolValue
                
                tasks.append(task)
            }
            
        // Callback
            completion(tasks: tasks, error: nil)
        }
    }
    
    func addTask(accessToken token: String, newTask: Task, completion: (added: Bool, error: String?) -> Void)
    {
        print("Adding task...")
        
        let body: NSDictionary = [
            "name"              : newTask.name!,
            "jobDescription"    : newTask.taskDescription!,
            "type"              : newTask.type!,
            "onFieldId"         : newTask.forField!.integerValue,
            "assignedById"      : newTask.assignedBy!.integerValue,
            "assignedToId"      : newTask.assignedTo!.integerValue,
            "DueDate"           : "\(newTask.dueDate!)",
            "rate"              : newTask.payRate!
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateTask.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
                print("addTask: request failed. \(error!.describe(details!))")
                completion(added: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(added: true, error: nil)
        }
    }
    
    func editTask(accessToken token: String, newTask: Task, completion: (edited: Bool, error: String?) -> Void)
    {
        print("Editing task...")
        
        let body: NSDictionary = [
            "name"              : newTask.name!,
            "jobDescription"    : newTask.taskDescription!,
            "type"              : newTask.type!,
            "onFieldId"         : newTask.forField!.integerValue,
            "assignedById"      : newTask.assignedBy!.integerValue,
            "assignedToId"      : newTask.assignedTo!.integerValue,
            "DateFinished"      : "\(newTask.completedOnDate!)",
            "DueDate"           : "\(newTask.dueDate!)",
            "state"             : newTask.state!,
            "rate"              : newTask.payRate!
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateTask.httpRequest(urlParameter: "\(newTask.id!.integerValue)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
                let details = response?["error_description"].string
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
                let details = response?["error_description"].string
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
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = self.dateFormat
                
                field.name              = fieldInfo["name"].stringValue
                field.area              = fieldInfo["size"].numberValue
                field.fieldDescription  = fieldInfo["fieldDescription"].stringValue
                field.parentOrgID       = fieldInfo["onOrg"].numberValue
                field.id                = fieldInfo["Id"].numberValue
                let createdOnString     = fieldInfo["CreatedAt"].stringValue
                field.createdOn         = dateFormatter.dateFromString(createdOnString)
                let updatedOnString     = fieldInfo["UpdatedAt"].stringValue
                field.updatedOn         = dateFormatter.dateFromString(updatedOnString)
                field.version           = fieldInfo["Version"].stringValue
                field.markedDeleted     = fieldInfo["Deleted"].boolValue
                
                fields.append(field)
            }
            
        // Callback
            completion(fields: fields, error: nil)
        }
    }
    
    func addField(accessToken token: String, newField: Field, completion: (added: Bool, error: String?) -> Void)
    {
        print("Creating a field...")
        
        let body: NSDictionary = [
            "name"              : newField.name!,
            "size"              : newField.area!,
            "fieldDescription"  : newField.fieldDescription!,
            "orgId"             : newField.parentOrgID!,
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateField.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
                print("createField: request failed. \(error!.describe(details!))")
                completion(added: false, error: error!.describe(details!))
                return
            }
            
        // Request successful
            completion(added: true, error: nil)
        }
    }
    
    func editField(accessToken token: String, newField: Field, completion: (edited: Bool, error: String?) -> Void)
    {
        print("Editing field...")
        
        let body: NSDictionary = [
            "name"              : newField.name!,
            "size"              : newField.area!,
            "fieldDescription"  : newField.fieldDescription!,
            "orgId"             : newField.parentOrgID!,
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateField.httpRequest(urlParameter: "\(newField.id!.integerValue)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
                let details = response?["error_description"].string
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
                let details = response?["error_description"].string
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
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = self.dateFormat
                
                staff.personID      = staffInfo["personID"].numberValue
                staff.organization  = staffInfo["atOrgID"].numberValue
                staff.role          = staffInfo["role"].stringValue
                staff.firstName     = staffInfo["firstName"].stringValue
                staff.lastName      = staffInfo["lastName"].stringValue
                staff.phone         = staffInfo["phone"].numberValue
                staff.id            = staffInfo["Id"].numberValue
                let createdOnString = staffInfo["CreatedAt"].stringValue
                staff.createdOn     = dateFormatter.dateFromString(createdOnString)
                let updatedOnString = staffInfo["UpdatedAt"].stringValue
                staff.updatedOn     = dateFormatter.dateFromString(updatedOnString)
                staff.version       = staffInfo["Version"].stringValue
                staff.markedDeleted = staffInfo["Deleted"].boolValue
                
                staffs.append(staff)
            }
            
        // Callback
            completion(staffs: staffs, error: nil)
        }
    }
    
    func addStaff(accessToken token: String, newStaff: Staff, completion: (added: Bool, error: String?) -> Void)
    {
        print("Adding staff...")
        
        let body: NSDictionary = [
            "personID"          : newStaff.personID!,
            "atOrgID"           : newStaff.organization!,
            "role"              : newStaff.role!,
            "firstName"         : newStaff.firstName!,
            "lastName"          : newStaff.lastName!,
            "phone"             : newStaff.phone!
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateStaff.httpRequest(), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
            "personID"          : newStaff.personID!,
            "atOrgID"           : newStaff.organization!,
            "role"              : newStaff.role!,
            "firstName"         : newStaff.firstName!,
            "lastName"          : newStaff.lastName!,
            "phone"             : newStaff.phone!
        ]
        
        let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateStaff.httpRequest(urlParameter: "\(newStaff.id!.integerValue)"), token: token)
        networkConnection.makeHTTPRequest() {
            (response, error) in
            
        // Request failed
            guard error == nil else
            {
                let details = response?["error_description"].string
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
                let details = response?["error_description"].string
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
























