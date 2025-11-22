//
//  QuoteViewModel.swift
//  FuegoVibe
//
//  Created by mac on 15/11/2025.
//

import Foundation
import Combine

@MainActor
class QuoteViewModel: ObservableObject {
    @Published var quoteOfTheDay: Quote?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let apiURL = "https://zenquotes.io/api/today"
    
    // 📥 Récupérer la citation du jour
    func fetchQuoteOfTheDay() async {
        isLoading = true
        errorMessage = ""
        
        guard let url = URL(string: apiURL) else {
            errorMessage = "Invalid URL"
            isLoading = false
            // Utiliser une citation de secours
            quoteOfTheDay = Quote.randomFallback
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Vérifier le statut HTTP
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // Décoder la réponse
            let quotes = try JSONDecoder().decode(QuotesResponse.self, from: data)
            
            if let firstQuote = quotes.first {
                self.quoteOfTheDay = firstQuote
                print("✅ Quote loaded: \(firstQuote.quote)")
            } else {
                // Pas de citation reçue, utiliser fallback
                self.quoteOfTheDay = Quote.randomFallback
            }
            
        } catch {
            print("❌ Error fetching quote: \(error)")
            errorMessage = "Could not load quote"
            // Utiliser une citation de secours
            self.quoteOfTheDay = Quote.randomFallback
        }
        
        isLoading = false
    }
    
    // 🔄 Rafraîchir la citation
    func refreshQuote() async {
        await fetchQuoteOfTheDay()
    }
    
    // 💾 Sauvegarder la citation dans UserDefaults pour cache
    func saveQuoteToCache(_ quote: Quote) {
        if let encoded = try? JSONEncoder().encode(quote) {
            UserDefaults.standard.set(encoded, forKey: "cachedQuote")
            UserDefaults.standard.set(Date(), forKey: "quoteCacheDate")
        }
    }
    
    // 📖 Charger la citation du cache
    func loadQuoteFromCache() -> Quote? {
        guard let data = UserDefaults.standard.data(forKey: "cachedQuote"),
              let quote = try? JSONDecoder().decode(Quote.self, from: data),
              let cacheDate = UserDefaults.standard.object(forKey: "quoteCacheDate") as? Date else {
            return nil
        }
        
        // Vérifier si le cache est encore valide (moins de 24h)
        let calendar = Calendar.current
        if calendar.isDateInToday(cacheDate) {
            return quote
        }
        
        return nil
    }
    
    // 🚀 Charger avec cache intelligent
    func loadQuoteWithCache() async {
        // Essayer de charger depuis le cache d'abord
        if let cachedQuote = loadQuoteFromCache() {
            self.quoteOfTheDay = cachedQuote
            print("📖 Loaded quote from cache")
            return
        }
        
        // Sinon, récupérer depuis l'API
        await fetchQuoteOfTheDay()
        
        // Sauvegarder dans le cache
        if let quote = quoteOfTheDay {
            saveQuoteToCache(quote)
        }
    }
}
