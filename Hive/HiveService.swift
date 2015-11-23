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
	
	//
    // MARK: - Methods
    //
    
    func download(user: User, completion: (error: String?) -> Void)
    {
		var errors: String!
		
    // Create a dispatch group to be notified when all requests finish
        let dispatchGroup = dispatch_group_create()
        
        dispatch_group_enter(dispatchGroup)
        self.getUser(user) {
            (didGet, remoteUser, error) -> Void in
            if didGet && remoteUser != nil
            {
                print("    ⋮  User downloaded from server?  -  \(user.updatedWithDetailsFromUser(remoteUser!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
                print("    ⋮  User couldn't be synced.")
				print(error)
				if errors != nil {
					errors = error
				}
				else {
					errors! += "\n\(error)"
				}
                dispatch_group_leave(dispatchGroup)
            }
        }
        
        dispatch_group_enter(dispatchGroup)
        self.getAllContacts(accessToken: user.accessToken!) {
            (didGet, contacts, error) in
            if didGet && contacts != nil
            {
                print("    ⋮  Contacts synced with server  -  \(Contact.updateAll(contacts!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
				print("    ⋮  Contacts couldn't be synced.")
				if errors != nil {
					errors = error
				}
				else {
					errors! += "\n\(error)"
				}
                dispatch_group_leave(dispatchGroup)
            }
        }
		
        dispatch_group_enter(dispatchGroup)
        self.getAllOrganisations(accessToken: user.accessToken!) {
            (didGet, orgs, error) in
            if didGet && orgs != nil
            {
                print("    ⋮  Organisations synced with server  -  \(Organisation.updateAll(orgs!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
				print("    ⋮  Farms couldn't be synced.")
				if errors != nil {
					errors = error
				}
				else {
					errors! += "\n\(error)"
				}
                dispatch_group_leave(dispatchGroup)
            }
        }
        
        dispatch_group_enter(dispatchGroup)
        self.getAllTasks(accessToken: user.accessToken!) {
            (didGet, tasks, error) in
            if didGet && tasks != nil
            {
                print("    ⋮  Tasks synced with server  -  \(Task.updateAll(tasks!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
				print("    ⋮  Tasks couldn't be synced.")
				if errors != nil {
					errors = error
				}
				else {
					errors! += "\n\(error)"
				}
                dispatch_group_leave(dispatchGroup)
            }
        }
        
        dispatch_group_enter(dispatchGroup)
        self.getAllFields(accessToken: user.accessToken!) {
            (didGet, fields, error) in
            if didGet && fields != nil
            {
                print("    ⋮  Fields synced with server  -  \(Field.updateAll(fields!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
				print("    ⋮  Fields couldn't be synced.")
				if errors != nil {
					errors = error
				}
				else {
					errors! += "\n\(error)"
				}
                dispatch_group_leave(dispatchGroup)
            }
        }
        
        dispatch_group_enter(dispatchGroup)
        self.getAllStaff(accessToken: user.accessToken!) {
            (didGet, staffs, error) in
            if didGet && staffs != nil
            {
                print("    ⋮  Staff synced with server  -  \(Staff.updateAll(staffs!))")
                dispatch_group_leave(dispatchGroup)
            }
            else
            {
				print("    ⋮  Staff couldn't be synced.")
				if errors != nil {
					errors = error
				}
				else {
					errors! += "\n\(error)"
				}
                dispatch_group_leave(dispatchGroup)
            }
        }
		
        // this block will be called async only when the above are done
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
            print("Sync complete.")
            completion (error: errors)
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
    
    enum Errors: Int, ErrorType
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
        
        func describe(details: String = "") -> String
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
























