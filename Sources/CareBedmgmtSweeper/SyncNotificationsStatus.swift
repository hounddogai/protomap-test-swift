import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncNotificationsStatus keeps of each SummarizeNotifications response.
struct SyncNotificationsStatusRecord {
    var status: String
    var reportID: String
}

/// Where SyncNotificationsStatus hands each record.
protocol SyncNotificationsStatusSink {
    func push(_ rec: SyncNotificationsStatusRecord) async throws
}

/// Writes records to acme.telehealth.v1.VideoVisitApprovalService.
struct SyncNotificationsStatusVideoVisitApproval: SyncNotificationsStatusSink {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func push(_ rec: SyncNotificationsStatusRecord) async throws {
        _ = try await client.listPendingVideoVisits(.with {
            $0.filter.region = rec.status
        })
    }
}

/// Hands records to acme.careplans.v1.VitalValidationService.
struct SyncNotificationsStatusVitalValidation: SyncNotificationsStatusSink {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func push(_ rec: SyncNotificationsStatusRecord) async throws {
        let request = Acme_Careplans_V1_ScoreVitalRequest.with {
            $0.vital.correlationID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreVital(request)
        }
    }
}

/// Reads acme.notifications.v1.NotificationQueryService/SummarizeNotifications and hands what it keeps to the sink of its kind.
enum SyncNotificationsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)
        let reply = try await source.summarizeNotifications(.with { $0.notificationID = "default-sync-notifications-status" })
        let row = SyncNotificationsStatusRecord(
            status: Kit.Text.normalize(reply.result.status),
            reportID: reply.reportID
        )
        let sinks: [String: any SyncNotificationsStatusSink] = [
            "video-visit-approval": SyncNotificationsStatusVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)),
            "vital-validation": SyncNotificationsStatusVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["SYNC_NOTIFICATIONS_STATUS_TARGET"] ?? ""] else {
            return
        }
        try await sink.push(row)
    }
}
