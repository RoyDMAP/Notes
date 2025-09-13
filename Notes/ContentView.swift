//
//  ContentView.swift
//  Notes
//
//  Created by Roy Dimapilis on 9/10/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newNoteText = ""
    @State private var sortByNewest = true

    // Use @FetchRequest with dynamic sort descriptors
    @FetchRequest private var items: FetchedResults<Item>

    init() {
        // Initialize with default sorting (newest first)
        self._items = FetchRequest<Item>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
            predicate: NSPredicate(format: "content != nil AND content != ''"),
            animation: .default
        )
    }

    var body: some View {
        NavigationView {
            VStack {
                // Header
                VStack {
                    Text("My Notes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                }

                // Sort Toggle
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Sort Method", selection: $sortByNewest) {
                        Text("Newest First").tag(true)
                        Text("Title A-Z").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)

                HStack {
                    TextField("Enter new note", text: $newNoteText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.sentences)
                        .disableAutocorrection(false)

                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()

                List {
                    ForEach(sortedItems, id: \.objectID) { item in
                        NavigationLink(destination: NoteDetailView(item: item)) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let content = item.content, !content.isEmpty {
                                    Text(content)
                                        .font(.headline)
                                        .lineLimit(1)
                                } else {
                                    Text("Empty Note")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                if let timestamp = item.timestamp {
                                    Text("\(timestamp, formatter: itemFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                deleteItem(item)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear All") {
                            clearAllItems()
                        }
                        .foregroundColor(.red)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            Text("Select a note") // Default detail view on iPad
        }
    }

    // Computed property to sort items based on current selection
    private var sortedItems: [Item] {
        let itemsArray = Array(items)
        if sortByNewest {
            return itemsArray.sorted { (item1, item2) in
                (item1.timestamp ?? Date.distantPast) > (item2.timestamp ?? Date.distantPast)
            }
        } else {
            return itemsArray.sorted { (item1, item2) in
                (item1.content ?? "").localizedCaseInsensitiveCompare(item2.content ?? "") == .orderedAscending
            }
        }
    }

    private func addItem() {
        let trimmedText = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            print("⚠️ Attempted to add empty note")
            return
        }

        print("📝 Adding new note: \(trimmedText)")
        
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.content = trimmedText
            newNoteText = ""
            
            // Debug: Print the item details
            print("✅ Created item with content: \(newItem.content ?? "nil")")
            print("✅ Created item with timestamp: \(newItem.timestamp ?? Date.distantPast)")

            do {
                try viewContext.save()
                print("✅ Successfully saved new note to Core Data")
                
                // Verify the save by counting items
                let request: NSFetchRequest<Item> = Item.fetchRequest()
                let count = try viewContext.count(for: request)
                print("📊 Total notes in database: \(count)")
                
            } catch {
                print("❌ Error saving new note: \(error)")
                let nsError = error as NSError
                print("Error details: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let sortedItemsArray = sortedItems
            offsets.map { sortedItemsArray[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("⚠️ Error deleting note: \(error.localizedDescription)")
            }
        }
    }

    private func deleteItem(_ item: Item) {
        withAnimation {
            viewContext.delete(item)

            do {
                try viewContext.save()
            } catch {
                print("⚠️ Error deleting note: \(error.localizedDescription)")
            }
        }
    }

    private func clearAllItems() {
        withAnimation {
            items.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("⚠️ Error clearing notes: \(error.localizedDescription)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    let context = PersistenceController.preview.container.viewContext
    return ContentView()
        .environment(\.managedObjectContext, context)
}
