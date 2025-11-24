//
//  EventView.swift
//  FuegoVibe
//
//  Created by mac on 15/11/2025.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var myEvents: [Event] = []  // Événements créés par l'utilisateur
    @Published var joinedEvents: [Event] = []  // Événements auxquels l'utilisateur participe
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var joinedEventsListener: ListenerRegistration?
    private var myEventsListener: ListenerRegistration?
    
    func fetchAllEvents() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let snapshot = try await db.collection("events")
                .whereField("isPublic", isEqualTo: true)
                .order(by: "startDate", descending: false)
                .getDocuments()
            
            self.events = snapshot.documents.compactMap { doc in
                Event.fromDictionary(doc.data(), id: doc.documentID)
            }
            
            print("✅ Loaded \(events.count) events")
        } catch {
            print("❌ Error fetching events: \(error)")
            errorMessage = "Failed to load events"
        }
        
        isLoading = false
    }
    
    func fetchMyEvents(userId: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let snapshot = try await db.collection("events")
                .whereField("organizerId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            self.myEvents = snapshot.documents.compactMap { doc in
                Event.fromDictionary(doc.data(), id: doc.documentID)
            }
            
            print("✅ Loaded \(myEvents.count) my events")
        } catch {
            print("❌ Error fetching my events: \(error)")
            errorMessage = "Failed to load your events"
        }
        
        isLoading = false
    }
    
    func fetchJoinedEvents(userId: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let snapshot = try await db.collection("events")
                .whereField("participantIds", arrayContains: userId)
                .order(by: "startDate", descending: false)
                .getDocuments()
            
            self.joinedEvents = snapshot.documents.compactMap { doc in
                Event.fromDictionary(doc.data(), id: doc.documentID)
            }
            
            print("✅ Loaded \(joinedEvents.count) joined events")
        } catch {
            print("❌ Error fetching joined events: \(error)")
            errorMessage = "Failed to load joined events"
        }
        
        isLoading = false
    }
    
    func createEvent(_ event: Event) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            let docRef = try await db.collection("events").addDocument(data: event.toDictionary())
            print("✅ Event created with ID: \(docRef.documentID)")
            
            // Recharger les événements
            await fetchAllEvents()
            
            isLoading = false
            return true
        } catch {
            print("❌ Error creating event: \(error)")
            errorMessage = "Failed to create event"
            isLoading = false
            return false
        }
    }
    
    func updateEvent(_ event: Event) async -> Bool {
        guard let eventId = event.id else {
            errorMessage = "Invalid event ID"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        
        do {
            try await db.collection("events").document(eventId).updateData(updatedEvent.toDictionary())
            print("✅ Event updated")
            
            // Recharger les événements
            await fetchAllEvents()
            
            isLoading = false
            return true
        } catch {
            print("❌ Error updating event: \(error)")
            errorMessage = "Failed to update event"
            isLoading = false
            return false
        }
    }
    
    func deleteEvent(_ eventId: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            try await db.collection("events").document(eventId).delete()
            print("✅ Event deleted")
            
            // Retirer de la liste locale
            events.removeAll { $0.id == eventId }
            myEvents.removeAll { $0.id == eventId }
            
            isLoading = false
            return true
        } catch {
            print("❌ Error deleting event: \(error)")
            errorMessage = "Failed to delete event"
            isLoading = false
            return false
        }
    }
    
    func joinEvent(_ event: Event, userId: String) async -> Bool {
        guard let eventId = event.id else {
            errorMessage = "Invalid event ID"
            return false
        }
        
        // Vérifier si déjà inscrit
        if event.isUserParticipating(userId: userId) {
            errorMessage = "You are already registered for this event"
            return false
        }
        
        // Vérifier si l'événement est complet
        if event.isFull {
            errorMessage = "This event is full"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await db.collection("events").document(eventId).updateData([
                "participantIds": FieldValue.arrayUnion([userId]),
                "currentParticipants": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: Date())
            ])
            
            print("✅ Joined event")
            
            // Les listeners mettront à jour automatiquement
            
            isLoading = false
            return true
        } catch {
            print("❌ Error joining event: \(error)")
            errorMessage = "Failed to join event"
            isLoading = false
            return false
        }
    }
    
    func leaveEvent(_ event: Event, userId: String) async -> Bool {
        guard let eventId = event.id else {
            errorMessage = "Invalid event ID"
            return false
        }
        
        // Vérifier si l'utilisateur participe
        if !event.isUserParticipating(userId: userId) {
            errorMessage = "You are not registered for this event"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await db.collection("events").document(eventId).updateData([
                "participantIds": FieldValue.arrayRemove([userId]),
                "currentParticipants": FieldValue.increment(Int64(-1)),
                "updatedAt": Timestamp(date: Date())
            ])
            
            print("✅ Left event")
            
            // Les listeners mettront à jour automatiquement
            
            isLoading = false
            return true
        } catch {
            print("❌ Error leaving event: \(error)")
            errorMessage = "Failed to leave event"
            isLoading = false
            return false
        }
    }
    
    func searchEvents(query: String) -> [Event] {
        guard !query.isEmpty else { return events }
        
        return events.filter { event in
            event.title.localizedCaseInsensitiveContains(query) ||
            event.description.localizedCaseInsensitiveContains(query) ||
            event.location.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterByCategory(_ category: EventCategory) -> [Event] {
        return events.filter { $0.category == category }
    }
    
    func filterByStatus(_ status: EventStatus) -> [Event] {
        return events.filter { $0.status == status }
    }
    
    func getFreeEvents() -> [Event] {
        return events.filter { $0.isFree }
    }
    
    func getPaidEvents() -> [Event] {
        return events.filter { !$0.isFree }
    }
    
    func getUpcomingEvents() -> [Event] {
        return events.filter { $0.startDate > Date() }
    }
    
    func startListening() {
        listener = db.collection("events")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Listener error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self.events = documents.compactMap { doc in
                        Event.fromDictionary(doc.data(), id: doc.documentID)
                    }
                    print("🔔 Events updated: \(self.events.count)")
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func startJoinedEventsListener(userId: String) {
        joinedEventsListener = db.collection("events")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Joined events listener error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self.joinedEvents = documents.compactMap { doc in
                        Event.fromDictionary(doc.data(), id: doc.documentID)
                    }
                    print("🔔 Joined events updated: \(self.joinedEvents.count)")
                }
            }
    }
    
    func stopJoinedEventsListener() {
        joinedEventsListener?.remove()
        joinedEventsListener = nil
    }
    
    func startMyEventsListener(userId: String) {
        myEventsListener = db.collection("events")
            .whereField("organizerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ My events listener error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self.myEvents = documents.compactMap { doc in
                        Event.fromDictionary(doc.data(), id: doc.documentID)
                    }
                    print("🔔 My events updated: \(self.myEvents.count)")
                }
            }
    }
    
    func stopMyEventsListener() {
        myEventsListener?.remove()
        myEventsListener = nil
    }
    
    nonisolated deinit {
        listener?.remove()
        joinedEventsListener?.remove()
        myEventsListener?.remove()
    }
}
