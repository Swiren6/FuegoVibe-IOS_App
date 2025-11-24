//
//  QuoteSplashView.swift
//  FuegoVibe
//
//  Created by Mac on 22/11/2025.
//

import SwiftUI

struct QuoteSplashView: View {
    let quote: Quote
    @Binding var isPresented: Bool
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var progress: Double = 0
    
    private let duration: Double = 30
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.9),
                    Color.pink.opacity(0.8),
                    Color.orange.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Particules flottantes en arrière-plan
            ParticlesView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Contenu de la citation
                VStack(spacing: 30) {
                    // Icône animée
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 10)
                        
                        Image(systemName: "quote.opening")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(scale == 1.0 ? -5 : 5))
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: scale)
                    }
                    .scaleEffect(scale)
                    
                    // Texte de la citation
                    VStack(spacing: 20) {
                        Text(quote.quote)
                            .font(.system(size: 28, weight: .medium, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 30)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        // Ligne décorative
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 60, height: 2)
                            .cornerRadius(1)
                        
                        Text("— \(quote.author)")
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundColor(.white.opacity(0.9))
                            .italic()
                    }
                }
                .opacity(opacity)
                .scaleEffect(scale)
                
                Spacer()
                
                // Barre de progression
                VStack(spacing: 12) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    
                    // Bouton Skip
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isPresented = false
                        }
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Animation d'entrée
            withAnimation(.easeOut(duration: 1.0)) {
                opacity = 1.0
                scale = 1.0
            }
            
            // Timer pour la progression
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if progress < 1.0 {
                    progress += 0.1 / duration
                } else {
                    timer.invalidate()
                    // Fermer automatiquement après 30 secondes
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// Vue pour les particules flottantes
struct ParticlesView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: 2)
                }
            }
            .onAppear {
                // Créer les particules initiales
                for _ in 0..<20 {
                    particles.append(Particle(
                        size: CGFloat.random(in: 3...8),
                        position: CGPoint(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                    ))
                }
                
                // Animer les particules
                animateParticles(in: geometry.size)
            }
        }
    }
    
    func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in 0..<particles.count {
                var particle = particles[i]
                particle.position.y -= CGFloat.random(in: 0.5...1.5)
                particle.position.x += CGFloat.random(in: -0.5...0.5)
                
                // Réinitialiser si sort de l'écran
                if particle.position.y < -10 {
                    particle.position.y = size.height + 10
                    particle.position.x = CGFloat.random(in: 0...size.width)
                }
                
                particles[i] = particle
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var size: CGFloat
    var position: CGPoint
}

#Preview {
    QuoteSplashView(
        quote: Quote.fallbackQuotes[0],
        isPresented: .constant(true)
    )
}
