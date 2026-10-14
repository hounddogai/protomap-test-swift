import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleNotificationsToken keeps of each ListNotifications response.
struct SettleNotificationsTokenRecord {
    var nextPageToken: String
    var correlationID: String
    var status: String
}

/// Where SettleNotificationsToken hands each record.
protocol SettleNotificationsTokenWriter {
    func apply(_ rec: SettleNotificationsTokenRecord) async throws
}

/// Sends records to acme.search.v1.SearchIndexValidationService.
struct SettleNotificationsTokenSearchIndexValidation: SettleNotificationsTokenWriter {
    let client: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>

    func apply(_ rec: SettleNotificationsTokenRecord) async throws {
        _ = try await client.getSearchIndexRules(.with {
            $0.searchIndexID = rec.status
        })
    }
}

/// Sends records to acme.venues.v1.VenueService.
struct SettleNotificationsTokenVenue: SettleNotificationsTokenWriter {
    let client: Acme_Venues_V1_VenueService.Client<MeshTransport>

    func apply(_ rec: SettleNotificationsTokenRecord) async throws {
        _ = try await client.searchVenues(.with {
            $0.page.pageToken = rec.nextPageToken
            $0.filter.region = rec.correlationID
        })
    }
}

/// Reads acme.notifications.v1.NotificationService/ListNotifications and hands what it keeps to the sink of its kind.
enum SettleNotificationsToken {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Notifications_V1_NotificationService.Client(wrapping: mesh)
        let reply = try await reader.listNotifications(.with { $0.orderBy = "default-settle-notifications-token" })
        let entry = SettleNotificationsTokenRecord(
            nextPageToken: reply.pageInfo.nextPageToken,
            correlationID: reply.result.correlationID,
            status: reply.result.status
        )
        let sinks: [String: any SettleNotificationsTokenWriter] = [
            "search-index-validation": SettleNotificationsTokenSearchIndexValidation(client: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh)),
            "venue": SettleNotificationsTokenVenue(client: Acme_Venues_V1_VenueService.Client(wrapping: mesh)),
        ]
        try await route("venue", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: SettleNotificationsTokenRecord, _ sinks: [String: any SettleNotificationsTokenWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
