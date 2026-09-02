//
//  EventViewModel.swift
//  FuegoVibe
//


import Foundation
import Combine
import FirebaseFirestore

@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var myEvents: [Event] = []
    @Published var joinedEvents: [Event] = []

    // FIX: Separate loading states instead of one shared isLoading
    @Published var isFetchingEvents = false
    @Published var isJoining = false
    @Published var isCreating = false
    @Published var isDeleting = false

    // Convenience computed var for views that just need "any loading"
    var isLoading: Bool { isFetchingEvents || isCreating || isDeleting }

    @Published var errorMessage = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var joinedEventsListener: ListenerRegistration?
    private var myEventsListener: ListenerRegistration?

    // MARK: - Fetch

    func fetchAllEvents() async {
        isFetchingEvents = true
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

        isFetchingEvents = false
    }

    func fetchMyEvents(userId: String) async {
        isFetchingEvents = true
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

        isFetchingEvents = false
    }

    func fetchJoinedEvents(userId: String) async {
        isFetchingEvents = true
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

        isFetchingEvents = false
    }

    // MARK: - CRUD

    func createEvent(_ event: Event) async -> Bool {
        isCreating = true
        errorMessage = ""

        do {
            let docRef = try await db.collection("events").addDocument(data: event.toDictionary())
            print("✅ Event created with ID: \(docRef.documentID)")
            await fetchAllEvents()
            isCreating = false
            return true
        } catch {
            print("❌ Error creating event: \(error)")
            errorMessage = "Failed to create event"
            isCreating = false
            return false
        }
    }

    func updateEvent(_ event: Event) async -> Bool {
        guard let eventId = event.id else {
            errorMessage = "Invalid event ID"
            return false
        }

        isCreating = true
        errorMessage = ""

        var updatedEvent = event
        updatedEvent.updatedAt = Date()

        do {
            try await db.collection("events").document(eventId).updateData(updatedEvent.toDictionary())
            print("✅ Event updated")
            await fetchAllEvents()
            isCreating = false
            return true
        } catch {
            print("❌ Error updating event: \(error)")
            errorMessage = "Failed to update event"
            isCreating = false
            return false
        }
    }

    func deleteEvent(_ eventId: String) async -> Bool {
        isDeleting = true
        errorMessage = ""

        do {
            try await db.collection("events").document(eventId).delete()
            print("✅ Event deleted")
            events.removeAll { $0.id == eventId }
            myEvents.removeAll { $0.id == eventId }
            isDeleting = false
            return true
        } catch {
            print("❌ Error deleting event: \(error)")
            errorMessage = "Failed to delete event"
            isDeleting = false
            return false
        }
    }

    // MARK: - Join / Leave

    func joinEvent(_ event: Event, userId: String) async -> Bool {
        guard let eventId = event.id else {
            errorMessage = "Invalid event ID"
            return false
        }

        if event.isUserParticipating(userId: userId) {
            errorMessage = "You are already registered for this event"
            return false
        }

        if event.isFull {
            errorMessage = "This event is full"
            return false
        }

        isJoining = true
        errorMessage = ""

        do {
            try await db.collection("events").document(eventId).updateData([
                "participantIds": FieldValue.arrayUnion([userId]),
                "currentParticipants": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: Date())
            ])

            print("✅ Joined event")
            isJoining = false
            return true
        } catch {
            print("❌ Error joining event: \(error)")
            errorMessage = "Failed to join event"
            isJoining = false
            return false
        }
    }

    func leaveEvent(_ event: Event, userId: String) async -> Bool {
        guard let eventId = event.id else {
            errorMessage = "Invalid event ID"
            return false
        }

        if !event.isUserParticipating(userId: userId) {
            errorMessage = "You are not registered for this event"
            return false
        }

        // FIX: Guard against currentParticipants going negative
        guard event.currentParticipants > 0 else {
            errorMessage = "Invalid participant count"
            return false
        }

        isJoining = true
        errorMessage = ""

        do {
            try await db.collection("events").document(eventId).updateData([
                "participantIds": FieldValue.arrayRemove([userId]),
                "currentParticipants": FieldValue.increment(Int64(-1)),
                "updatedAt": Timestamp(date: Date())
            ])

            print("✅ Left event")
            isJoining = false
            return true
        } catch {
            print("❌ Error leaving event: \(error)")
            errorMessage = "Failed to leave event"
            isJoining = false
            return false
        }
    }

    // MARK: - Filters

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

    func getFreeEvents() -> [Event] { events.filter { $0.isFree } }
    func getPaidEvents() -> [Event] { events.filter { !$0.isFree } }
    func getUpcomingEvents() -> [Event] { events.filter { $0.startDate > Date() } }

    // MARK: - Real-time Listeners

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
