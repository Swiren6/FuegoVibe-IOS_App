//
//  AuthViewModel.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
     
    private let ADMIN_EMAIL = "sirine@gmail.com"
    
    @Published var user: FirebaseAuth.User?
    @Published var currentAppUser: AppUser?
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            if let user = user {
                Task {
                    await self?.fetchUserData(uid: user.uid)
                }
            } else {
                self?.currentAppUser = nil
            }
        }
    }
    
    func fetchUserData(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if let data = document.data() {
                let roleString = data["role"] as? String ?? "user"
                let role = UserRole(rawValue: roleString) ?? .user
                let email = data["email"] as? String ?? ""
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                
                var appUser = AppUser(uid: uid, email: email, role: role, createdAt: createdAt)
                appUser.id = uid
                
                self.currentAppUser = appUser
            } else {
                await createUserDocument(uid: uid, email: user?.email ?? "")
            }
        } catch {
            print("❌ Error fetching user: \(error)")
            errorMessage = "Failed to load user data"
        }
    }
    
    private func createUserDocument(uid: String, email: String) async {
    
        let role: UserRole = (email == ADMIN_EMAIL) ? .admin : .user
        let createdAt = Date()
        
        do {
            try await db.collection("users").document(uid).setData([
                "uid": uid,
                "email": email,
                "role": role.rawValue,
                "createdAt": Timestamp(date: createdAt)
            ])
            
            var appUser = AppUser(uid: uid, email: email, role: role, createdAt: createdAt)
            appUser.id = uid
            self.currentAppUser = appUser
            
            print("✅ User created with role: \(role.rawValue)")
        } catch {
            print("❌ Error creating user: \(error)")
            errorMessage = "Failed to create user profile"
        }
    }
    
    
    
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            await fetchUserData(uid: result.user.uid)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    

    func signUp(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
            await createUserDocument(uid: result.user.uid, email: email)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.currentAppUser = nil
            errorMessage = ""
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    var isAdmin: Bool {
        return currentAppUser?.isAdmin ?? false
    }
}
