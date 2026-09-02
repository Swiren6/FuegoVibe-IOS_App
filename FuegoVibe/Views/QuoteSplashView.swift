//
//  QuoteSplashView.swift
//  FuegoVibe
//
//  REDESIGN + BUGFIX:
//  - Dark gradient background (fire → violet)
//  - Clean typography, serif quote text
//  - Task-based timer (no memory leak)
//  - Smooth dismiss animation
//

import SwiftUI

struct QuoteSplashView: View {
    let quote: Quote
    @Binding var isPresented: Bool

    @State private var contentOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.92
    @State private var progress: Double = 0
    @State private var splashTask: Task<Void, Never>?

    private let duration: Double = 30

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.05, blue: 0.12),
                    Color(red: 0.15, green: 0.07, blue: 0.22),
                    Color(red: 0.07, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glows
            RadialGradient(
                colors: [FV.Colors.fire.opacity(0.20), .clear],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [FV.Colors.violet.opacity(0.15), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Floating particles
            ParticlesView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Quote content ──
                VStack(spacing: 32) {

                    // Quote mark
                    ZStack {
                        Circle()
                            .fill(FV.Colors.surface.opacity(0.6))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(FV.Colors.fire.opacity(0.25), lineWidth: 1)
                            )

                        Image(systemName: "quote.opening")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(FV.fireGradient)
                    }

                    // Quote text + author
                    VStack(spacing: 20) {
                        Text(quote.quote)
                            .font(.system(size: 24, weight: .medium, design: .serif))
                            .foregroundColor(FV.Colors.primary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 32)

                        VStack(spacing: 8) {
                            Rectangle()
                                .fill(FV.fireGradient)
                                .frame(width: 40, height: 2)
                                .cornerRadius(1)

                            Text("— \(quote.author)")
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundColor(FV.Colors.secondary)
                                .italic()
                        }
                    }
                }
                .opacity(contentOpacity)
                .scaleEffect(contentScale)

                Spacer()

                // ── Progress + skip ──
                VStack(spacing: 16) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(FV.Colors.surfaceHigh)
                                .frame(height: 3)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(FV.fireGradient)
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 40)

                    Button(action: dismissSplash) {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(FV.Colors.secondary)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(FV.Colors.surface.opacity(0.7))
                            .cornerRadius(20)
                            .overlay(
                                Capsule()
                                    .stroke(FV.Colors.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                contentOpacity = 1.0
                contentScale = 1.0
            }

            splashTask = Task {
                let steps = Int(duration / 0.1)
                for _ in 0..<steps {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    progress = min(progress + (1.0 / Double(steps)), 1.0)
                }
                guard !Task.isCancelled else { return }
                dismissSplash()
            }
        }
        .onDisappear {
            splashTask?.cancel()
            splashTask = nil
        }
    }

    private func dismissSplash() {
        splashTask?.cancel()
        splashTask = nil
        withAnimation(.easeOut(duration: 0.4)) {
            contentOpacity = 0
            contentScale = 0.95
        }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            isPresented = false
        }
    }
}

// MARK: - Particles View (bug-fixed, Task-based)

struct ParticlesView: View {
    @State private var particles: [Particle] = []
    @State private var particleTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(
                            p.isWarm
                                ? FV.Colors.fire.opacity(p.opacity)
                                : FV.Colors.violet.opacity(p.opacity)
                        )
                        .frame(width: p.size, height: p.size)
                        .position(p.position)
                        .blur(radius: 1.5)
                }
            }
            .onAppear {
                for _ in 0..<24 {
                    particles.append(Particle(size: geo.size))
                }

                particleTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(50))
                        guard !Task.isCancelled else { return }

                        for i in 0..<particles.count {
                            particles[i].position.y -= CGFloat.random(in: 0.4...1.2)
                            particles[i].position.x += CGFloat.random(in: -0.4...0.4)
                            if particles[i].position.y < -10 {
                                particles[i] = Particle(
                                    size: geo.size,
                                    startY: geo.size.height + 10
                                )
                            }
                        }
                    }
                }
            }
            .onDisappear {
                particleTask?.cancel()
                particleTask = nil
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
    var isWarm: Bool

    init(size canvasSize: CGSize, startY: CGFloat? = nil) {
        self.size = CGFloat.random(in: 2...6)
        self.position = CGPoint(
            x: CGFloat.random(in: 0...canvasSize.width),
            y: startY ?? CGFloat.random(in: 0...canvasSize.height)
        )
        self.opacity = Double.random(in: 0.10...0.30)
        self.isWarm = Bool.random()
    }
}

#Preview {
    QuoteSplashView(
        quote: Quote.fallbackQuotes[0],
        isPresented: .constant(true)
    )
}
