//
//  ProfileViewModel.swift
//  ToDoDone
//
//  Created by Mahmut Özkan on 28.06.2024.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class ProfileViewModel: ObservableObject{
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { try await loadImage() } }
    }
    
    @Published var profileImage: Image?
    private let storage = Storage.storage()
    
    func loadImage() async throws {
        guard let item = selectedItem else {return}
        guard let imageData = try await item.loadTransferable(type: Data.self) else {return}
        guard let uiImage = UIImage(data: imageData) else { return }
        DispatchQueue.main.async {
            self.profileImage = Image(uiImage: uiImage)
        }
        
        
        try await uploadProfileImage(imageData: imageData)
    }
    
    func uploadProfileImage(imageData: Data) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is logged in")
            return
        }
        let storageRef = storage.reference().child("profileImages/\(userID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        let downloadURL = try await storageRef.downloadURL()
        await updateUserProfileImageURL(downloadURL: downloadURL)
    }
    
    func updateUserProfileImageURL(downloadURL: URL) async {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        
        do{
            try await db.collection("users").document(userID).updateData([
                "profileImageURL": downloadURL.absoluteString
            ])
            
        }catch{
            print("Error updating profile image URL : \(error.localizedDescription)")
        }
    }
    
}


