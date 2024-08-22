//
//  ToDoViewModel.swift
//  ToDoDone
//
//  Created by Mahmut Özkan on 27.06.2024.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ToDoViewModel: ObservableObject {
    @Published var items: [ToDoItem] = []
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        fetchToDos()
    }
    
    func fetchToDos() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is logged in!")
            return
        }
        
        listenerRegistration = db.collection("users")
            .document(userID)
            .collection("tasks")
            .order(by: "timestamp", descending: false) // En son girilen en sonda olacak şekilde sıralama
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents in snapshot!")
                    return
                }
                
                let fetchedItems: [ToDoItem] = documents.compactMap { document -> ToDoItem? in
                    let result = try? document.data(as: ToDoItem.self)
                     // Log each fetched item
                    return result
                }
                
                 // Log the entire fetched array
                DispatchQueue.main.async {
                    self.items = fetchedItems // Update items on the main thread
                }
            }
    }
    
    
    
    
    func deleteTask(_ task: ToDoItem) {
            guard let userID = Auth.auth().currentUser?.uid,
                  let itemID = task.id else {
                print("User or item ID not found!")
                return
            }
            
            db.collection("users")
                .document(userID)
                .collection("tasks")
                .document(itemID)
                .delete { error in
                    if let error = error {
                        print("Error deleting task: \(error.localizedDescription)")
                    } else {
                        print("Task deleted successfully")
                        DispatchQueue.main.async {
                            // Local array'den silinen görevi çıkart
                            self.items.removeAll { $0.id == task.id }
                        }
                    }
                }
        }
        
    deinit {
        listenerRegistration?.remove()
    }
    
    static func withMockData() -> ToDoViewModel {
            
            let viewModel = ToDoViewModel()
            viewModel.items = [
                ToDoItem(id: "1", title: "Mock Task 1", description: "This is a mock task 1", isCompleted: false),
                ToDoItem(id: "2", title: "Mock Task 2", description: "This is a mock task 2", isCompleted: true),
                ToDoItem(id: "3", title: "Mock Task 3", description: "This is a mock task 3", isCompleted: false)
            ]
            return viewModel
        }
    
    }
