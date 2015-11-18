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
    
    class func getAll() -> [Task]?
    {
        let request = NSFetchRequest(entityName: Task.entityName)
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
    
    class func getAllTypes() -> [String]
    {
        var allTypes = [String]()
        allTypes.append(TaskType.Drilling.rawValue)
        allTypes.append(TaskType.Tilling.rawValue)
        allTypes.append(TaskType.Filling.rawValue)
        allTypes.append(TaskType.Chilling.rawValue)
        
        return allTypes
    }
    
    class func updateAllTasks(newTasks: [Task]) -> Int
    {
        var count = 0
        
        guard let tasks = Task.getAll() else
        {
            print("Local database has no tasks. Adding new tasks.")
            for newTask in newTasks
            {
                newTask.moveToPersistentStore()
            }
            return newTasks.count
        }
        
        for newTask in newTasks
        {
            for task in tasks
            {
                if task.updatedWithDetailsFromTask(newTask)
                {
                    count++
                }
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
