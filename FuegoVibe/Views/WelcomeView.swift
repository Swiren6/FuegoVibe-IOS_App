//
//  WelcomeView.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.9, green: 0.3, blue: 0.9), // Rose/Magenta
                        Color(red: 0.6, green: 0.4, blue: 1.0)  // Violet
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Wave Pattern Overlay
                WavePatternView()
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo et Nom de l'App
                    VStack(spacing: 20) {
                        // Logo Placeholder (tu peux le remplacer par ton logo)
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                                .frame(width: 140, height: 140)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            // Icône de feu stylisée
                            Image(systemName: "flame.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.9, green: 0.3, blue: 0.9),
                                            Color(red: 0.6, green: 0.4, blue: 1.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text("FuegoVibe")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Spacer()
                    
                    // Boutons
                    VStack(spacing: 20) {
                        // Get Started Button
                        NavigationLink(destination: SignUpView()) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.7, green: 0.5, blue: 1.0))
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
                                )
                        }
                        .padding(.horizontal, 40)
                        
                        // Already have an account
                        NavigationLink(destination: SignInView()) {
                            Text("I already have an account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .underline()
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}

// Vue pour créer le motif de vagues
struct WavePatternView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let waveHeight: CGFloat = 15
                let wavelength: CGFloat = 40
                
                // Dessiner plusieurs lignes de vagues
                for line in 0..<Int(height / 20) {
                    let yOffset = CGFloat(line) * 20
                    
                    path.move(to: CGPoint(x: 0, y: yOffset))
                    
                    for x in stride(from: 0, through: width, by: 5) {
                        let relativeX = x / wavelength
                        let sine = sin(relativeX) * waveHeight
                        path.addLine(to: CGPoint(x: x, y: yOffset + sine))
                    }
                }
            }
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    WelcomeView()
}
