//
//  DetailView.swift
//  Notes
//
//  Created by Roy Dimapilis on 9/10/25.
//

import SwiftUI
import CoreData

struct NoteDetailView: View {
    let item: Item
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                // Editing Mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Note")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .frame(minHeight: 200)
                }
                .padding()
            } else {
                // Display Mode
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let content = item.content, !content.isEmpty {
                            Text(content)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled) // Allow text selection
                        } else {
                            Text("Empty Note")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let timestamp = item.timestamp {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Created: \(timestamp, formatter: itemFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Show word and character count
                                let wordCount = (item.content ?? "").components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                                let charCount = item.content?.count ?? 0
                                
                                Text("\(wordCount) words, \(charCount) characters")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .navigationTitle(isEditing ? "Edit Note" : "Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isEditing {
                    // Cancel and Save buttons when editing
                    Button("Cancel") {
                        cancelEditing()
                    }
                    
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    // Only Edit and Delete buttons when viewing
                    Button("Edit") {
                        startEditing()
                    }
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .onAppear {
            // Initialize edited content when view appears
            editedContent = item.content ?? ""
        }
    }
    
    // MARK: - Private Methods
    
    private func startEditing() {
        editedContent = item.content ?? ""
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = true
        }
    }
    
    private func cancelEditing() {
        // Reset to original content
        editedContent = item.content ?? ""
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
        }
    }
    
    private func saveChanges() {
        let trimmedContent = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else {
            // Don't save empty notes
            return
        }
        
        // Update the item
        item.content = trimmedContent
        
        // Optionally update timestamp to show when it was last modified
        // item.timestamp = Date()
        
        do {
            try viewContext.save()
            print("✅ Successfully updated note")
            withAnimation(.easeInOut(duration: 0.3)) {
                isEditing = false
            }
        } catch {
            print("❌ Error saving changes: \(error)")
            // You might want to show an alert to the user here
        }
    }
    
    private func deleteNote() {
        viewContext.delete(item)
        
        do {
            try viewContext.save()
            print("✅ Successfully deleted note")
            dismiss() // Navigate back to the list
        } catch {
            print("❌ Error deleting note: \(error)")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleItem = Item(context: context)
    sampleItem.content = "This is a sample note with some content that demonstrates how the note detail view works with longer text content."
    sampleItem.timestamp = Date()
    
    return NavigationView {
        NoteDetailView(item: sampleItem)
    }
    .environment(\.managedObjectContext, context)
}
