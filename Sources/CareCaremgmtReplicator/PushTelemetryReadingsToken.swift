import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushTelemetryReadingsToken keeps of each BrowseTelemetryReadings response.
struct PushTelemetryReadingsTokenRecord {
    var nextPageToken: String
    var message: String
    var correlationID: String
}

/// Where PushTelemetryReadingsToken hands each record.
protocol PushTelemetryReadingsTokenWriter {
    func forward(_ rec: PushTelemetryReadingsTokenRecord) async throws
}

/// Passes records to acme.patientapp.v1.CareInboxNotificationService.
struct PushTelemetryReadingsTokenCareInboxNotification: PushTelemetryReadingsTokenWriter {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func forward(_ rec: PushTelemetryReadingsTokenRecord) async throws {
        _ = try await client.sendCareInboxTestNotice(.with {
            $0.careInboxID = rec.correlationID
            $0.details.templateID = rec.message
            $0.details.channel = rec.nextPageToken
        })
    }
}

/// Writes records to acme.notifications.v1.NotificationQueryService.
struct PushTelemetryReadingsTokenNotificationQuery: PushTelemetryReadingsTokenWriter {
    let client: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>

    func forward(_ rec: PushTelemetryReadingsTokenRecord) async throws {
        _ = try await client.browseNotifications(.with {
            $0.orderBy = rec.message
        })
    }
}

/// Sends records to acme.identity.v1.UserQueryService.
struct PushTelemetryReadingsTokenUserQuery: PushTelemetryReadingsTokenWriter {
    let client: Acme_Identity_V1_UserQueryService.Client<MeshTransport>

    func forward(_ rec: PushTelemetryReadingsTokenRecord) async throws {
        _ = try await client.countUsers(.with {
            $0.filter.region = rec.message
            $0.filter.ownerID = rec.nextPageToken
            $0.filter.query = rec.correlationID
        })
    }
}

/// Writes records to acme.performers.v1.PerformerQueryService.
struct PushTelemetryReadingsTokenPerformerQuery: PushTelemetryReadingsTokenWriter {
    let client: Acme_Performers_V1_PerformerQueryService.Client<MeshTransport>

    func forward(_ rec: PushTelemetryReadingsTokenRecord) async throws {
        let request = Acme_Performers_V1_SuggestPerformersRequest.with {
            $0.orderBy = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestPerformers(request)
        }
    }
}

/// Reads acme.telematics.v1.TelemetryReadingQueryService/BrowseTelemetryReadings and hands what it keeps to the sink of its kind.
enum PushTelemetryReadingsToken {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Telematics_V1_TelemetryReadingQueryService.Client(wrapping: mesh)
        let response = try await source.browseTelemetryReadings(.with { $0.orderBy = "default-push-telemetry-readings-token" })
        let entry = PushTelemetryReadingsTokenRecord(
            nextPageToken: response.pageInfo.nextPageToken,
            message: response.result.message,
            correlationID: Kit.Text.normalize(response.result.correlationID)
        )
        try await act("performer-query", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: PushTelemetryReadingsTokenRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "care-inbox-notification": { try await PushTelemetryReadingsTokenCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)).forward(rec) },
            "notification-query": { try await PushTelemetryReadingsTokenNotificationQuery(client: Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)).forward(rec) },
            "user-query": { try await PushTelemetryReadingsTokenUserQuery(client: Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)).forward(rec) },
            "performer-query": { try await PushTelemetryReadingsTokenPerformerQuery(client: Acme_Performers_V1_PerformerQueryService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
