//
//  DetailView.swift
//  Notes
//
//  Created by Roy Dimapilis on 9/10/25.
//

import SwiftUI
import CoreData

struct NoteDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: Item
    @State private var editedContent = ""
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Created:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let ts = item.timestamp {
                    Text("\(ts, formatter: itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if isEditing {
                // Editing mode
                VStack {
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            } else {
                // Display content
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let content = item.content, !content.isEmpty {
                            Text(content)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("This note has no content.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .navigationTitle("Note Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
        }
        .onAppear {
            // preload the content
            editedContent = item.content ?? ""
        }
    }
    
    // MARK: - Edit actions
    private func startEditing() {
        editedContent = item.content ?? ""
        isEditing = true
    }
    
    private func saveChanges() {
        item.content = editedContent   // ✅ use typed property
        do {
            try viewContext.save()
            isEditing = false
            print("Content saved: '\(editedContent)'")
        } catch {
            let nsError = error as NSError
            print("Save error: \(nsError)")
        }
    }
    
    private func cancelEditing() {
        editedContent = item.content ?? ""
        isEditing = false
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
    let sampleItem = Item(context: context)
    sampleItem.timestamp = Date()
    sampleItem.content = "Sample preview note content"
    
    return NoteDetailView(item: sampleItem)
        .environment(\.managedObjectContext, context)
}
