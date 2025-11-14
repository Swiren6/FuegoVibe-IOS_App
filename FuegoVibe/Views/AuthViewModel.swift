//
//  AuthViewModelAuthViewModel.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {     
    @Published var user: User?
    @Published var errorMessage = ""

    init() {
        self.user = Auth.auth().currentUser
    }

    func signIn(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
