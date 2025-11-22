//
//  QuoteCardView.swift
//  FuegoVibe
//
//  Created by mac on 15/11/2025.
//

import SwiftUI

// Carte pour afficher la citation du jour
struct QuoteCardView: View {
    let quote: Quote
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "quote.opening")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Quote of the Day")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.yellow)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            // Citation
            Text("\"\(quote.quote)\"")
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            // Auteur
            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            isAnimating = true
        }
    }
}

// Version compacte de la carte
struct QuoteCardCompactView: View {
    let quote: Quote
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.title2)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(quote.quote)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("— \(quote.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Version minimaliste
struct QuoteCardMinimalView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.quote)
                .font(.callout)
                .foregroundColor(.primary)
                .italic()
            
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview("Full Card") {
    QuoteCardView(quote: Quote.fallbackQuotes[0])
        .padding()
}

#Preview("Compact Card") {
    QuoteCardCompactView(quote: Quote.fallbackQuotes[0])
        .padding()
}

#Preview("Minimal Card") {
    QuoteCardMinimalView(quote: Quote.fallbackQuotes[0])
        .padding()
}
