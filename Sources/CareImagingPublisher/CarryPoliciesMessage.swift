import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryPoliciesMessage keeps of each FindPolicies response.
struct CarryPoliciesMessageRecord {
    var message: String
    var status: String
    var nextPageToken: String
    var correlationID: String
}

/// Where CarryPoliciesMessage hands each record.
protocol CarryPoliciesMessageWriter {
    func deliver(_ rec: CarryPoliciesMessageRecord) async throws
}

/// Sends records to acme.notifications.v1.NotificationQueryService.
struct CarryPoliciesMessageNotificationQuery: CarryPoliciesMessageWriter {
    let client: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>

    func deliver(_ rec: CarryPoliciesMessageRecord) async throws {
        _ = try await client.peekNotification(.with {
            $0.notificationID = rec.status
        })
    }
}

/// Writes records to acme.licensing.v1.SoftwareLicenseQueryService.
struct CarryPoliciesMessageSoftwareLicenseQuery: CarryPoliciesMessageWriter {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func deliver(_ rec: CarryPoliciesMessageRecord) async throws {
        _ = try await client.countSoftwareLicenses(.with {
            $0.filter.query = rec.message
            $0.filter.region = rec.nextPageToken
        })
    }
}

/// Reads acme.insurance.v1.PolicyQueryService/FindPolicies and hands what it keeps to the sink of its kind.
enum CarryPoliciesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Insurance_V1_PolicyQueryService.Client(wrapping: mesh)
        let response = try await origin.findPolicies(.with { $0.orderBy = "live-carry-policies-message" })
        let entry = CarryPoliciesMessageRecord(
            message: response.result.message,
            status: response.result.status,
            nextPageToken: Kit.Text.normalize(response.pageInfo.nextPageToken),
            correlationID: response.result.correlationID
        )
        let sinks: [String: any CarryPoliciesMessageWriter] = [
            "notification-query": CarryPoliciesMessageNotificationQuery(client: Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)),
            "software-license-query": CarryPoliciesMessageSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)),
        ]
        try await route("notification-query", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: CarryPoliciesMessageRecord, _ sinks: [String: any CarryPoliciesMessageWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
