//
//  Persistence.swift
//  Notes
//
//  Created by Roy Dimapilis on 9/10/25.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        for i in 0..<3 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.content = "Sample note \(i + 1)"
        }
        
        do {
            try viewContext.save()
            print("✅ Preview data saved successfully")
        } catch {
            print("❌ Preview data save failed: \(error)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Try to find the Core Data model
        let modelNames = ["DataModel", "Model", "Notes", "NotesApp", "CoreData"]
        var foundContainer: NSPersistentContainer?
        
        for modelName in modelNames {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") {
                if let model = NSManagedObjectModel(contentsOf: modelURL) {
                    print("✅ Found Core Data model: \(modelName)")
                    foundContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
                    break
                }
            }
        }
        
        if foundContainer == nil {
            print("⚠️ No Core Data model found in bundle, using fallback: DataModel")
            container = NSPersistentContainer(name: "DataModel")
        } else {
            container = foundContainer!
        }
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            print("🧪 Using in-memory store for testing")
        } else {
            // Print where the database will be stored
            if let storeURL = container.persistentStoreDescriptions.first?.url {
                print("💾 Database location: \(storeURL)")
            }
        }
        
        // Configure store options for better reliability
        let storeDescription = container.persistentStoreDescriptions.first!
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ Core Data store loading failed: \(error), \(error.userInfo)")
                // In a real app, you might want to handle this more gracefully
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            } else {
                print("✅ Core Data store loaded successfully")
                if let url = storeDescription.url {
                    print("📁 Store URL: \(url)")
                }
            }
        })
        
        // Enable automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Set merge policy to handle conflicts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Convenience method to save context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                print("❌ Core Data save error: \(error)")
                let nsError = error as NSError
                print("Error details: \(nsError), \(nsError.userInfo)")
            }
        } else {
            print("ℹ️ No changes to save")
        }
    }
}
