//
//  QuoteViewModel.swift
//  FuegoVibe
//  Created by mac on 22/11/2025.
//


import Foundation
import Combine

@MainActor
class QuoteViewModel: ObservableObject {
    @Published var quoteOfTheDay: Quote?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let apiURL = "https://zenquotes.io/api/today"
    
    func fetchQuoteOfTheDay() async {
        isLoading = true
        errorMessage = ""
        
        print("🔍 Tentative de chargement de la citation...")
        
        guard let url = URL(string: apiURL) else {
            print("❌ URL invalide")
            errorMessage = "Invalid URL"
            isLoading = false
            // Utiliser une citation de secours
            quoteOfTheDay = Quote.randomFallback
            print("✅ Citation de secours utilisée: \(quoteOfTheDay?.quote ?? "nil")")
            return
        }
        
        do {
            print("🌐 Requête API vers: \(apiURL)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Vérifier le statut HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("📡 Réponse HTTP: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // Décoder la réponse
            let quotes = try JSONDecoder().decode(QuotesResponse.self, from: data)
            
            if let firstQuote = quotes.first {
                self.quoteOfTheDay = firstQuote
                print("✅ Citation chargée avec succès: \(firstQuote.quote)")
            } else {
                print("⚠️ Aucune citation dans la réponse, utilisation du fallback")
                // Pas de citation reçue, utiliser fallback
                self.quoteOfTheDay = Quote.randomFallback
            }
            
        } catch {
            print("❌ Erreur lors du chargement: \(error.localizedDescription)")
            errorMessage = "Could not load quote"
            // Utiliser une citation de secours
            self.quoteOfTheDay = Quote.randomFallback
            print("✅ Citation de secours utilisée après erreur: \(quoteOfTheDay?.quote ?? "nil")")
        }
        
        isLoading = false
    }
    
    //  Rafraîchir la citation
    func refreshQuote() async {
        await fetchQuoteOfTheDay()
    }
    
    //  Sauvegarder la citation dans UserDefaults pour cache
    func saveQuoteToCache(_ quote: Quote) {
        if let encoded = try? JSONEncoder().encode(quote) {
            UserDefaults.standard.set(encoded, forKey: "cachedQuote")
            UserDefaults.standard.set(Date(), forKey: "quoteCacheDate")
            print("💾 Citation sauvegardée dans le cache")
        }
    }
    
    //  Charger la citation du cache
    func loadQuoteFromCache() -> Quote? {
        guard let data = UserDefaults.standard.data(forKey: "cachedQuote"),
              let quote = try? JSONDecoder().decode(Quote.self, from: data),
              let cacheDate = UserDefaults.standard.object(forKey: "quoteCacheDate") as? Date else {
            print("📖 Pas de cache disponible")
            return nil
        }
        
        // Vérifier si le cache est encore valide (moins de 24h)
        let calendar = Calendar.current
        if calendar.isDateInToday(cacheDate) {
            print("📖 Citation chargée depuis le cache: \(quote.quote)")
            return quote
        }
        
        print("📖 Cache expiré")
        return nil
    }
    
    //  Charger avec cache intelligent
    func loadQuoteWithCache() async {
        print("🚀 Démarrage loadQuoteWithCache")
        
        // Essayer de charger depuis le cache d'abord
        if let cachedQuote = loadQuoteFromCache() {
            self.quoteOfTheDay = cachedQuote
            print("✅ Citation du cache utilisée")
            return
        }
        
        print("🌐 Pas de cache, chargement depuis l'API...")
        
        // Sinon, récupérer depuis l'API
        await fetchQuoteOfTheDay()
        
        // Sauvegarder dans le cache
        if let quote = quoteOfTheDay {
            saveQuoteToCache(quote)
        } else {
            // Si toujours nil, forcer un fallback
            print("⚠️ Quote toujours nil après fetchQuoteOfTheDay, forçage du fallback")
            self.quoteOfTheDay = Quote.randomFallback
            saveQuoteToCache(Quote.randomFallback)
        }
        
        print("✅ loadQuoteWithCache terminé. Quote finale: \(quoteOfTheDay?.quote ?? "NIL")")
    }
}
