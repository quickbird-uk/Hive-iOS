//
//  DataService.swift
//  Hive
//
//  Created by Animesh. on 29/09/2015.
//  Copyright © 2015 Quickbird. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Data
{
// Singleton
    static let shared = Data()
    
    var permanentContext: NSManagedObjectContext
    var temporaryContext: NSManagedObjectContext
    
// Prevent others from using the default initializer of this class
    private init()
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
        
        self.permanentContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.permanentContext.persistentStoreCoordinator = storeCoordinator
        
        self.temporaryContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.temporaryContext.persistentStoreCoordinator = storeCoordinator
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
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
        }
    }
    
    //
    // MARK: - Methods
    //
    
    func initMessage() -> String
    {
        return "Core Data stack initialized successfully."
    }
    
    func saveContext(message sender: String) -> Bool
    {
        if permanentContext.hasChanges
        {
            do
            {
                try permanentContext.save()
                print("\nMain context saved.", terminator: "\t")
                print(sender)
                return true
            }
            catch
            {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
        return false
    }
    
    func deleteAllData()
    {
        User.deleteAll()
        Organisation.deleteAll()
        Field.deleteAll()
        Staff.deleteAll()
        Contact.deleteAll()
        Task.deleteAll()
    }
}


















