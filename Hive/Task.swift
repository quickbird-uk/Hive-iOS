//
//  Task.swift
//  Hive
//
//  Created by Animesh. on 14/10/2015.
//  Copyright © 2015 Animesh. All rights reserved.
//

import Foundation
import CoreData

class Task: NSManagedObject
{
    //
    // MARK: - Properties
    //
    
    static let entityName = "Task"
    @NSManaged var assignedByID: NSNumber?
    @NSManaged var assignedToID: NSNumber?
    @NSManaged var completedOnDate: NSDate?
    @NSManaged var dueDate: NSDate?
    @NSManaged var forFieldID: NSNumber?
    @NSManaged var forOrganizationID: NSNumber?
    @NSManaged var id: NSNumber?
    @NSManaged var lastAction: String?
    @NSManaged var name: String?
	@NSManaged var timeTaken: NSNumber?
    @NSManaged var payRate: NSNumber?
    @NSManaged var state: String?
    @NSManaged var taskDescription: String?
    @NSManaged var type: String?
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
		static let assignedByID			= "assignedByID"
		static let assignedToID			= "assignedToID"
		static let completedOnDate		= "completedOnDate"
		static let dueDate				= "dueDate"
		static let forFieldID			= "forFieldID"
		static let forOrganisationID		= "forOrganisationID"
		static let lastAction			= "lastAction"
		static let name					= "name"
		static let timeTaken				= "timeTaken"
		static let payRate				= "payRate"
		static let state					= "state"
		static let taskDescription		= "taskDescription"
		static let type					= "type"
		static let createdOn				= "createdOn"
		static let updatedOn				= "updatedOn"
		static let version				= "version"
		static let markedDeleted			= "markedDeleted"
		
		private init() { }
	}
	
    //
    // MARK: - Instance Methods
    //
    
    func isTheSameAsTask(other: Task) -> Bool
    {
        return self.id == other.id
    }
    
    private func save(newTask: Task) -> Bool
    {
        id                  = newTask.id
        assignedByID        = newTask.assignedByID
        assignedToID        = newTask.assignedToID
        completedOnDate     = newTask.completedOnDate
        dueDate             = newTask.dueDate
        forFieldID          = newTask.forFieldID
        forOrganizationID   = newTask.forOrganizationID
        lastAction          = newTask.lastAction
        name                = newTask.name
		timeTaken			= newTask.timeTaken
        payRate             = newTask.payRate
        state               = newTask.state
        taskDescription     = newTask.taskDescription
        type                = newTask.type
        version             = newTask.version
        createdOn           = newTask.createdOn
        updatedOn           = newTask.updatedOn
        markedDeleted       = newTask.markedDeleted
        
        return Data.shared.saveContext(message: "Task with name \(self.name) saved.")
    }
    
    func updatedWithDetailsFromTask(other: Task) -> Bool
    {
        if self.isTheSameAsTask(other)
        {
			if other.updatedOn!.timeIntervalSinceDate(self.updatedOn!) > 0
            {
                return save(other)
            }
            else
            {
				let accessToken = User.get()!.accessToken!
				var updated = false
				HiveService.shared.updateTask(self, accessToken: accessToken) {
					(didUpdate, updatedTask, error) -> Void in
					if didUpdate && error == nil {
						updated = self.save(updatedTask!)
					}
				}
				return updated
            }
        }
        else
        {
            print("\nParameter task object is not the same as the stale task object.")
            return false
        }
    }
    
    func moveToPersistentStore() -> Task?
    {
        if self.managedObjectContext == Data.shared.permanentContext
        {
            print("Task object is already stored in permanent context.")
            return self
        }
        else
        {
            let persistentTask = NSEntityDescription.insertNewObjectForEntityForName(Task.entityName, inManagedObjectContext: Data.shared.permanentContext) as! Task
            print("Moving task to persistent store...")
            if persistentTask.save(self)
            {
                return persistentTask
            }
            return nil
        }
    }
    
    func remove()
    {
        Data.shared.permanentContext.deleteObject(self)
        Data.shared.saveContext(message: "\nDeleting tasks with name \(self.name) and id \(self.id).")
    }
    
    //
    // MARK: - Class Methods
    //
    
    class func temporary() -> Task
    {
        let tempTask = NSEntityDescription.insertNewObjectForEntityForName(Task.entityName, inManagedObjectContext: Data.shared.temporaryContext) as! Task
		tempTask.updatedOn = NSDate()
		tempTask.createdOn = NSDate()
		return tempTask
    }
    
    class func getTaskWithID(id: NSNumber) -> Task?
    {
        let request = NSFetchRequest(entityName: Task.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as! [Task]
            print("\nNumber of tasks with id \(id) = \(result.count)")
            return result.first
        }
        catch
        {
            print("\nCouldn't find any tasks with ID = \(id).")
            return nil
        }
    }
    
	class func getAll(filter: String! = nil) -> [Task]?
    {
        let request = NSFetchRequest(entityName: Task.entityName)
		
		if filter != nil
		{
			request.predicate = NSPredicate(format: "state == %@", filter)
		}
		
        do {
            let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Task]
            print("\nTotal number of tasks in main context = \(result?.count)")
			if result?.count > 0 {
				return result
			}
			else {
				return nil
			}
        }
        catch
        {
            print("Couldn't fetch any tasks.")
            return nil
        }
    }
	
	class func getTasksForField(fieldID: Int!, withState state: String!) -> [Task]?
	{
		let request = NSFetchRequest(entityName: Task.entityName)
		request.predicate = NSPredicate(format: "forFieldID == %d AND state == %@", fieldID, state)
		
		do {
			let result = try Data.shared.permanentContext.executeFetchRequest(request) as? [Task]
			if result?.count > 0 {
				return result
			}
			else {
				return nil
			}
		}
		catch {
			return nil
		}
	}

    class func getAllTypes() -> [String]
    {
        var allTypes = [String]()
        allTypes.append(TaskType.Drilling.rawValue)
        allTypes.append(TaskType.Tilling.rawValue)
        allTypes.append(TaskType.Filling.rawValue)
        allTypes.append(TaskType.Chilling.rawValue)
        
        return allTypes
    }
    
    class func updateAll(newTasks: [Task]) -> Int
    {
        var count = 0
		var taskToSync: Task!
		var matchFound = false
        
        guard let tasks = Task.getAll() else
        {
            print("Local database has no tasks. Adding new tasks.")
            for newTask in newTasks
            {
                newTask.moveToPersistentStore()
            }
            return newTasks.count
        }
        
		for newTask	in newTasks {
			for task in tasks {
				if task.isTheSameAsTask(newTask) {
					matchFound = true
					taskToSync = task
					break
				}
			}
			if matchFound {
				taskToSync.updatedWithDetailsFromTask(newTask)
				count++
			}
			else {
				newTask.moveToPersistentStore()
				count++
			}
		}
		
        return count
    }
    
    class func deleteAll()
    {
        guard let tasks = Task.getAll() else
        {
            print("Nothing to delete here in Tasks.")
            return
        }
        
        for task in tasks
        {
            task.remove()
        }
    }
}

enum TaskState: String
{
	case Pending = "Pending"
	case Assigned = "Assigned"
	case InProgress = "In Progress"
	case Paused = "Paused"
	case Finished = "Finished"
}

enum TaskType: String
{
    case Drilling   = "Drilling"
    case Tilling    = "Tilling"
    case Filling    = "Filling"
    case Chilling   = "Chilling"
}

//
// MARK: - Quickbird API Methods
//

extension HiveService
{
	func didUpdateTask(task: Task, fromJSON: JSON?) -> Bool
	{
		guard let json = fromJSON else
		{
			print("HiveService.didUpdateTask(_: fromJSON: ) - Server sent nothing in response.")
			return false
		}
		print(json)
		task.name               = json[Task.Key.name].stringValue
		task.taskDescription    = json[Task.Key.taskDescription].stringValue
		task.type               = json[Task.Key.type].stringValue
		task.forFieldID         = json[Task.Key.forFieldID].intValue
		task.assignedByID       = json[Task.Key.assignedByID].intValue
		task.assignedToID       = json[Task.Key.assignedToID].intValue
		let dueDateString       = json[Task.Key.dueDate].stringValue
		task.dueDate            = self.dateFormatter.dateFromString(dueDateString)
		let finishDateString    = json[Task.Key.completedOnDate].stringValue
		task.completedOnDate    = self.dateFormatter.dateFromString(finishDateString)
		task.timeTaken			= json[Task.Key.timeTaken].doubleValue
		task.state              = json[Task.Key.state].stringValue
		task.payRate            = json[Task.Key.payRate].numberValue
		task.id                 = json[Task.Key.id].intValue
		let createdOnString     = json[Task.Key.createdOn].stringValue
		task.createdOn          = self.dateFormatter.dateFromString(createdOnString)
		let updatedOnString     = json[Task.Key.updatedOn].stringValue
		task.updatedOn          = self.dateFormatter.dateFromString(updatedOnString)
		task.version            = json[Task.Key.version].stringValue
		task.markedDeleted      = json[Task.Key.markedDeleted].boolValue
		
		print(task)
		return true
	}
	
	func getAllTasks(accessToken accessToken: String, completion: (didGet: Bool, tasks: [Task]?, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.ReadTasks.httpRequest(), token: accessToken)
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didGet: false, tasks: nil, error: error!.describe(details))
				return
			}
			
			guard let jsonArray = response else
			{
				completion(didGet: false, tasks: nil, error: "Server sent nothing in response.")
				return
			}
			
			var tasks = [Task]()
			for info in jsonArray
			{
				let taskInfo = info.1
				let task = Task.temporary()
				
				if self.didUpdateTask(task, fromJSON: taskInfo) {
					tasks.append(task)
				}
			}
			
			completion(didGet: true, tasks: tasks, error: nil)
		}
	}
	
	func addTask(task: Task, accessToken: String, completion: (didAdd: Bool, newTask: Task?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Task.Key.name				: task.name!,
			Task.Key.taskDescription		: task.taskDescription!,
			Task.Key.type				: task.type!,
			Task.Key.state				: task.state!,
			Task.Key.forFieldID			: task.forFieldID!.integerValue,
			Task.Key.assignedByID		: task.assignedByID!.integerValue,
			Task.Key.assignedToID		: task.assignedToID!.integerValue,
			Task.Key.dueDate				: "\(task.dueDate!)",
			Task.Key.payRate				: 66.6
		]
		
		print(body)
		print("\(task.dueDate!)")
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.CreateTask.httpRequest(), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in

			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didAdd: false, newTask: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateTask(task, fromJSON: response) {
				completion(didAdd: true, newTask: task, error: nil)
			}
			else {
				completion(didAdd: true, newTask: nil, error: "Server sent an empty response. Sync your Hive now to stay up-to-date.")
			}
		}
	}
	
	func updateTask(task: Task, accessToken: String, completion: (didUpdate: Bool, updatedTask: Task?, error: String?) -> Void)
	{
		let body: NSDictionary = [
			Task.Key.name             : task.name!,
			Task.Key.taskDescription  : task.taskDescription!,
			Task.Key.type             : task.type!,
			Task.Key.forFieldID       : task.forFieldID!.integerValue,
			Task.Key.assignedByID     : task.assignedByID!.integerValue,
			Task.Key.assignedToID     : task.assignedToID!.integerValue,
			Task.Key.timeTaken		  : task.timeTaken!.doubleValue,
			Task.Key.completedOnDate  : "\(task.completedOnDate!)",
			Task.Key.dueDate          : "\(task.dueDate!)",
			Task.Key.state            : task.state!,
			Task.Key.payRate          : task.payRate!,
			Task.Key.version			  : task.version!,
			Task.Key.id				  : task.id!
		]
		
		let networkConnection = NetworkService(bodyAsJSON: body, request: API.UpdateTask.httpRequest(urlParameter: "/\(task.id!.integerValue)"), token: accessToken)
		
		networkConnection.makeHTTPRequest() {
			(response, error) in
			
			guard error == nil else
			{
				let details = response?[self.errorDescriptionKey].stringValue ?? "Something bad happened."
				completion(didUpdate: false, updatedTask: nil, error: error!.describe(details))
				return
			}
			
			if self.didUpdateTask(task, fromJSON: response) {
				completion(didUpdate: true, updatedTask: task, error: nil)
			}
			else {
				completion(didUpdate: true, updatedTask: nil, error: "Server sent an empty response. Sync your Hive now to stay up-to-date.")
			}
		}
	}
	
	func deleteTaskWithID(taskID: Int, accessToken: String, completion: (didDelete: Bool, error: String?) -> Void)
	{
		let networkConnection = NetworkService(request: API.DeleteTask.httpRequest(urlParameter: "/\(taskID)"), token: accessToken)
		
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
