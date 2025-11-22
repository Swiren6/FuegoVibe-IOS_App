//
//  QuoteModel.swift
//  FuegoVibe
//
//  Created by mac on 15/11/2025.
//

import Foundation

// Modèle pour les citations de ZenQuotes
struct Quote: Codable, Identifiable {
    var id: String { quote }  // Utilise la citation comme ID
    let quote: String
    let author: String
    let html: String?
    
    enum CodingKeys: String, CodingKey {
        case quote = "q"
        case author = "a"
        case html = "h"
    }
}

// Réponse de l'API (retourne un tableau)
typealias QuotesResponse = [Quote]

// Extension pour des citations par défaut en cas d'erreur
extension Quote {
    static let fallbackQuotes: [Quote] = [
        Quote(quote: "The only limit to our realization of tomorrow is our doubts of today.", author: "Franklin D. Roosevelt", html: nil),
        Quote(quote: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", html: nil),
        Quote(quote: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", html: nil),
        Quote(quote: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", html: nil),
        Quote(quote: "It always seems impossible until it's done.", author: "Nelson Mandela", html: nil),
        Quote(quote: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson", html: nil),
        Quote(quote: "The only way to do great work is to love what you do.", author: "Steve Jobs", html: nil),
        Quote(quote: "If you can dream it, you can do it.", author: "Walt Disney", html: nil),
        Quote(quote: "Start where you are. Use what you have. Do what you can.", author: "Arthur Ashe", html: nil),
        Quote(quote: "The secret of getting ahead is getting started.", author: "Mark Twain", html: nil)
    ]
    
    // Citation aléatoire de secours
    static var randomFallback: Quote {
        fallbackQuotes.randomElement() ?? fallbackQuotes[0]
    }
}
