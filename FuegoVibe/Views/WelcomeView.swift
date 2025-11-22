

//
//  WelcomeView.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var sparkleRotation: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background animé
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                // Wave Pattern Overlay
                WavePatternView()
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo et Nom de l'App
                    VStack(spacing: 20) {
                        // Logo avec animations multiples
                        ZStack {
                            // Cercles de lueur pulsante
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 140 + CGFloat(index * 30), height: 140 + CGFloat(index * 30))
                                    .scaleEffect(pulseScale)
                                    .opacity(glowOpacity)
                                    .animation(
                                        .easeInOut(duration: 2.0)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.3),
                                        value: pulseScale
                                    )
                            }
                            
                            // Fond blanc avec ombre
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white)
                                .frame(width: 140, height: 140)
                                .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 10)
                                .shadow(color: .pink.opacity(0.3), radius: 30, x: 0, y: 15)
                            
                            // Particules scintillantes autour du logo
                            ForEach(0..<8) { index in
                                Circle()
                                    .fill(Color.yellow.opacity(0.8))
                                    .frame(width: 4, height: 4)
                                    .offset(x: cos(sparkleRotation + Double(index) * .pi / 4) * 80,
                                           y: sin(sparkleRotation + Double(index) * .pi / 4) * 80)
                                    .opacity(isAnimating ? 1.0 : 0.0)
                            }
                            
                            // Icône de feu stylisée avec rotation et échelle
                            Image(systemName: "flame.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.9, green: 0.3, blue: 0.9),
                                            Color(red: 1.0, green: 0.5, blue: 0.3),
                                            Color(red: 0.6, green: 0.4, blue: 1.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .rotationEffect(.degrees(rotationAngle))
                                .scaleEffect(pulseScale)
                                .shadow(color: .orange.opacity(0.6), radius: 10)
                        }
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        
                        // Nom de l'app avec effet de brillance
                        ZStack {
                            // Ombre du texte
                            Text("FuegoVibe")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.black.opacity(0.3))
                                .blur(radius: 3)
                                .offset(y: 2)
                            
                            // Texte principal avec gradient
                            Text("FuegoVibe")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color.yellow.opacity(0.9), .white],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                        }
                        .opacity(isAnimating ? 1.0 : 0.0)
                        
                        // Tagline animé
                        Text("Experience Events Like Never Before")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 1.0).delay(0.5), value: isAnimating)
                    }
                    
                    Spacer()
                    
                    // Boutons
                    VStack(spacing: 20) {
                        // Get Started Button avec effet de hover
                        NavigationLink(destination: SignUpView()) {
                            HStack {
                                Text("Get Started")
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 0.7, green: 0.5, blue: 1.0))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.white)
                                        .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 5)
                                    
                                    // Effet de brillance
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.5), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                }
                            )
                        }
                        .padding(.horizontal, 40)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: isAnimating)
                        
                        // Already have an account
                        NavigationLink(destination: SignInView()) {
                            HStack(spacing: 4) {
                                Text("I already have an account")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(0.5), value: isAnimating)
                    }
                    .padding(.bottom, 60)
                }
            }
            .onAppear {
                // Démarrer toutes les animations
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
                
                // Animation continue de la rotation
                withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                // Animation continue du pulse
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseScale = 1.1
                    glowOpacity = 0.6
                }
                
                // Animation continue des particules scintillantes
                withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                    sparkleRotation = 2 * .pi
                }
            }
        }
    }
}

// MARK: - Gradient Animé
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.9, green: 0.3, blue: 0.9), // Rose/Magenta
                Color(red: 0.6, green: 0.4, blue: 1.0), // Violet
                Color(red: 1.0, green: 0.5, blue: 0.3)  // Orange
            ]),
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Vagues Animées
struct WavePatternView: View {
    @State private var waveOffset: CGFloat = 0
    
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
                        let relativeX = (x + waveOffset) / wavelength
                        let sine = sin(relativeX) * waveHeight
                        path.addLine(to: CGPoint(x: x, y: yOffset + sine))
                    }
                }
            }
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                waveOffset = 40
            }
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeView()
}
