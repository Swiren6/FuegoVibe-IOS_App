//
//  EventModel.swift
//  FuegoVibe
//


import Foundation
import FirebaseFirestore

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

enum EventStatus: String, Codable {
    case upcoming = "upcoming"
    case ongoing = "ongoing"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct Event: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var category: EventCategory
    var status: EventStatus

    var startDate: Date
    var endDate: Date

    var location: String
    var address: String?
    var latitude: Double?
    var longitude: Double?

    var organizerId: String
    var organizerEmail: String

    var maxParticipants: Int?
    var currentParticipants: Int
    var participantIds: [String]

    var imageURL: String?
    var sourceURL: String?   // External ticketing URL (e.g. teskerti.tn, monticket.tn)

    var createdAt: Date
    var updatedAt: Date

    var isFree: Bool
    var price: Double?
    // FIX: was "USD", now "TND" to match the "DT" displayed in the UI
    var currency: String

    var isPublic: Bool

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
        self.currency = "TND" // FIX: was "USD"
        self.isPublic = isPublic
    }

    var isFull: Bool {
        guard let max = maxParticipants else { return false }
        return currentParticipants >= max
    }

    func isUserParticipating(userId: String) -> Bool {
        return participantIds.contains(userId)
    }

    func isOrganizer(userId: String) -> Bool {
        return organizerId == userId
    }

    var spotsLeft: Int? {
        guard let max = maxParticipants else { return nil }
        return max - currentParticipants
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }

    var isPast: Bool { endDate < Date() }

    var isOngoing: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }
}

// MARK: - Firestore Serialization

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

        if let address = address { dict["address"] = address }
        if let latitude = latitude { dict["latitude"] = latitude }
        if let longitude = longitude { dict["longitude"] = longitude }
        if let maxParticipants = maxParticipants { dict["maxParticipants"] = maxParticipants }
        if let imageURL = imageURL { dict["imageURL"] = imageURL }
        if let sourceURL = sourceURL { dict["sourceURL"] = sourceURL }
        if let price = price { dict["price"] = price }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any], id: String) -> Event? {
        guard
            let title = dict["title"] as? String,
            let description = dict["description"] as? String,
            let categoryString = dict["category"] as? String,
            let statusString = dict["status"] as? String,
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
            let isPublic = dict["isPublic"] as? Bool
        else {
            return nil
        }

        // FIX: Fallback to .other if category string is unknown (e.g. "Food" from import scripts)
        let category = EventCategory(rawValue: categoryString)
            ?? EventCategory.allCases.first(where: {
                categoryString.lowercased().contains($0.rawValue.lowercased().components(separatedBy: " ").first ?? "")
            })
            ?? .other

        // FIX: Fallback to .upcoming if status string is unknown
        let status = EventStatus(rawValue: statusString) ?? .upcoming

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
        event.sourceURL = dict["sourceURL"] as? String
        event.currency = dict["currency"] as? String ?? "TND"

        return event
    }
}
