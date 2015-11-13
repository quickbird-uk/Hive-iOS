//
//  LoadModelOperation.swift
//  Hive
//
//  Abstract:
//  This file contains the code to create the Core Data stack.
//
//  Created by Animesh. on 26/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import CoreData

/**
    An `Operation` subclass that loads the Core Data stack. If this operation fails,
    it will produce an `AlertOperation` that will offer to retry the operation.
*/
class LoadModelOperation: Operation
{
    //
    // MARK: Properties
    //

    let loadHandler: NSManagedObjectContext -> Void
    
    //
    // MARK: Initialization
    //
    
    init(loadHandler: NSManagedObjectContext -> Void)
    {
        self.loadHandler = loadHandler

        super.init()
        
        // We only want one of these going at a time.
        addCondition(MutuallyExclusive<LoadModelOperation>())
    }
    
    override func execute()
    {
    // CoreData model file resource has the same name as the .xcdatamodeld in the project
        guard let modelURL = NSBundle.mainBundle().URLForResource("Hive", withExtension: "momd") else
        {
            fatalError("Error loading data model from bundle.")
        }
        
        guard let objectModel = NSManagedObjectModel(contentsOfURL: modelURL) else
        {
            fatalError("Error initializing the managed object model from: \(modelURL)")
        }
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        
        let managedContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedContext.persistentStoreCoordinator = storeCoordinator
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let docURL = urls[urls.endIndex-1]
            
    // The directory the application uses to store the Core Data store file.
    // This project uses a file named "SingleViewCoreData.sqlite" in the
    // application's document directory.
        let storeURL = docURL.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        do {
            try storeCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        }
        catch {
            fatalError("Error migrating store: \(error)")
        }
        
        var error: NSError?
        
        if !storeCoordinator.persistentStores.isEmpty {
            loadHandler(managedContext)
            error = nil
        }
        
        finishWithError(error)
    }
    
    private func createStore(persistentStoreCoordinator: NSPersistentStoreCoordinator, atURL URL: NSURL?, type: String = NSSQLiteStoreType) -> NSError?
    {
        var error: NSError?
        do {
            let _ = try persistentStoreCoordinator.addPersistentStoreWithType(type, configuration: nil, URL: URL, options: nil)
        }
        catch let storeError as NSError {
            error = storeError
        }
        
        return error
    }
    
    private func destroyStore(persistentStoreCoordinator: NSPersistentStoreCoordinator, atURL URL: NSURL, type: String = NSSQLiteStoreType)
    {
        do {
            let _ = try persistentStoreCoordinator.destroyPersistentStoreAtURL(URL, withType: type, options: nil)
        }
        catch { }
    }
    
    override func finished(errors: [NSError])
    {
        guard let firstError = errors.first where userInitiated else { return }

        /*
            We failed to load the model on a user initiated operation try and present
            an error.
        */
        
        let alert = AlertOperation()

        alert.title = "Unable to load database"
        
        alert.message = "An error occurred while loading the database. \(firstError.localizedDescription). Please try again later."
        
        // No custom action for this button.
        alert.addAction("Retry Later", style: .Cancel)
        
        // Declare this as a local variable to avoid capturing self in the closure below.
        let handler = loadHandler
        
        /*
            For this operation, the `loadHandler` is only ever invoked if there are
            no errors, so if we get to this point we know that it was not executed.
            This means that we can offer to the user to try loading the model again,
            simply by creating a new copy of the operation and giving it the same
            loadHandler.
        */
        alert.addAction("Retry Now") { alertOperation in
            let retryOperation = LoadModelOperation(loadHandler: handler)

            retryOperation.userInitiated = true
            
            alertOperation.produceOperation(retryOperation)
        }

        produceOperation(alert)
    }
}
