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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default
    )
    private var items: FetchedResults<Item>

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

                List(items) { item in
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

                .listStyle(.insetGrouped) // 👌 modern style
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

    private func addItem() {
        let trimmedText = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.content = trimmedText   // ✅ save note content
            newNoteText = ""

            do {
                try viewContext.save()
            } catch {
                print("⚠️ Error saving new note: \(error.localizedDescription)")
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
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
