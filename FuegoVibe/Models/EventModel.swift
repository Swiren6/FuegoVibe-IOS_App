//
//  EventModel.swift
//  FuegoVibe
//
//  Created by mac on 15/11/2025.
//



import Foundation
import FirebaseFirestore

// Catégories d'événements
enum EventCategory: String, Codable, CaseIterable {
    case music = "Music"
    case sports = "Sports"
    case arts = "Arts"
    case food = "Food & Drink"
    case business = "Business"
    case technology = "Technology"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .music: return "music.note"
        case .sports: return "sportscourt"
        case .arts: return "paintpalette"
        case .food: return "fork.knife"
        case .business: return "briefcase"
        case .technology: return "laptopcomputer"
        case .other: return "star"
        }
    }
    
    var color: String {
        switch self {
        case .music: return "purple"
        case .sports: return "green"
        case .arts: return "pink"
        case .food: return "orange"
        case .business: return "blue"
        case .technology: return "indigo"
        case .other: return "gray"
        }
    }
}

// Statut de l'événement
enum EventStatus: String, Codable {
    case upcoming = "upcoming"
    case ongoing = "ongoing"
    case completed = "completed"
    case cancelled = "cancelled"
}

// Modèle Event
struct Event: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var category: EventCategory
    var status: EventStatus
    
    // Date et heure
    var startDate: Date
    var endDate: Date
    
    // Localisation
    var location: String
    var address: String?
    var latitude: Double?
    var longitude: Double?
    
    // Organisation
    var organizerId: String  // UID de l'organisateur
    var organizerEmail: String
    
    // Participants
    var maxParticipants: Int?
    var currentParticipants: Int
    var participantIds: [String]  // Liste des UIDs des participants
    
    // Médias
    var imageURL: String?
    
    // Métadonnées
    var createdAt: Date
    var updatedAt: Date
    
    // Prix
    var isFree: Bool
    var price: Double?
    var currency: String
    
    // Visibilité
    var isPublic: Bool
    
    // Initializer
    init(
        title: String,
        description: String,
        category: EventCategory,
        startDate: Date,
        endDate: Date,
        location: String,
        organizerId: String,
        organizerEmail: String,
        maxParticipants: Int? = nil,
        isFree: Bool = true,
        price: Double? = nil,
        isPublic: Bool = true
    ) {
        self.title = title
        self.description = description
        self.category = category
        self.status = .upcoming
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.organizerId = organizerId
        self.organizerEmail = organizerEmail
        self.maxParticipants = maxParticipants
        self.currentParticipants = 0
        self.participantIds = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFree = isFree
        self.price = price
        self.currency = "USD"
        self.isPublic = isPublic
    }
    
    // Vérifier si l'événement est complet
    var isFull: Bool {
        guard let max = maxParticipants else { return false }
        return currentParticipants >= max
    }
    
    // Vérifier si l'utilisateur participe
    func isUserParticipating(userId: String) -> Bool {
        return participantIds.contains(userId)
    }
    
    // Vérifier si l'utilisateur est l'organisateur
    func isOrganizer(userId: String) -> Bool {
        return organizerId == userId
    }
    
    // Nombre de places restantes
    var spotsLeft: Int? {
        guard let max = maxParticipants else { return nil }
        return max - currentParticipants
    }
    
    // Formater la date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    // Vérifier si l'événement est passé
    var isPast: Bool {
        return endDate < Date()
    }
    
    // Vérifier si l'événement est en cours
    var isOngoing: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }
}

//  pour Firestore
extension Event {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "description": description,
            "category": category.rawValue,
            "status": status.rawValue,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "location": location,
            "organizerId": organizerId,
            "organizerEmail": organizerEmail,
            "currentParticipants": currentParticipants,
            "participantIds": participantIds,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isFree": isFree,
            "currency": currency,
            "isPublic": isPublic
        ]
        
        if let address = address {
            dict["address"] = address
        }
        if let latitude = latitude {
            dict["latitude"] = latitude
        }
        if let longitude = longitude {
            dict["longitude"] = longitude
        }
        if let maxParticipants = maxParticipants {
            dict["maxParticipants"] = maxParticipants
        }
        if let imageURL = imageURL {
            dict["imageURL"] = imageURL
        }
        if let price = price {
            dict["price"] = price
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Event? {
        guard
            let title = dict["title"] as? String,
            let description = dict["description"] as? String,
            let categoryString = dict["category"] as? String,
            let category = EventCategory(rawValue: categoryString),
            let statusString = dict["status"] as? String,
            let status = EventStatus(rawValue: statusString),
            let startTimestamp = dict["startDate"] as? Timestamp,
            let endTimestamp = dict["endDate"] as? Timestamp,
            let location = dict["location"] as? String,
            let organizerId = dict["organizerId"] as? String,
            let organizerEmail = dict["organizerEmail"] as? String,
            let currentParticipants = dict["currentParticipants"] as? Int,
            let participantIds = dict["participantIds"] as? [String],
            let createdTimestamp = dict["createdAt"] as? Timestamp,
            let updatedTimestamp = dict["updatedAt"] as? Timestamp,
            let isFree = dict["isFree"] as? Bool,
            let currency = dict["currency"] as? String,
            let isPublic = dict["isPublic"] as? Bool
        else {
            return nil
        }
        
        var event = Event(
            title: title,
            description: description,
            category: category,
            startDate: startTimestamp.dateValue(),
            endDate: endTimestamp.dateValue(),
            location: location,
            organizerId: organizerId,
            organizerEmail: organizerEmail,
            maxParticipants: dict["maxParticipants"] as? Int,
            isFree: isFree,
            price: dict["price"] as? Double,
            isPublic: isPublic
        )
        
        event.id = id
        event.status = status
        event.currentParticipants = currentParticipants
        event.participantIds = participantIds
        event.createdAt = createdTimestamp.dateValue()
        event.updatedAt = updatedTimestamp.dateValue()
        event.address = dict["address"] as? String
        event.latitude = dict["latitude"] as? Double
        event.longitude = dict["longitude"] as? Double
        event.imageURL = dict["imageURL"] as? String
        event.currency = currency
        
        return event
    }
}
