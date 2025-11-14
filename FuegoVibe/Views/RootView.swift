//
//  RootView.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        Group {
            if authVM.user != nil {
                // ✅ Utilisateur connecté → Afficher le contenu principal
                ContentView()
            } else {
                // ✅ Pas d'utilisateur → Afficher l'écran de connexion
                NavigationView {
                    SignInView()
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}
