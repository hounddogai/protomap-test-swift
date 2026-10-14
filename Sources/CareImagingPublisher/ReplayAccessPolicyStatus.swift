import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayAccessPolicyStatus keeps of each DeleteAccessPolicy response.
struct ReplayAccessPolicyStatusRecord {
    var status: String
    var message: String
}

/// Where ReplayAccessPolicyStatus hands each record.
protocol ReplayAccessPolicyStatusWriter {
    func deliver(_ rec: ReplayAccessPolicyStatusRecord) async throws
}

/// Writes records to acme.yards.v1.YardCalculationService.
struct ReplayAccessPolicyStatusYardCalculation: ReplayAccessPolicyStatusWriter {
    let client: Acme_Yards_V1_YardCalculationService.Client<MeshTransport>

    func deliver(_ rec: ReplayAccessPolicyStatusRecord) async throws {
        _ = try await client.getYardRates(.with {
            $0.yardID = rec.message
        })
    }
}

/// Sends records to acme.telehealth.v1.TriageLifecycleService.
struct ReplayAccessPolicyStatusTriageLifecycle: ReplayAccessPolicyStatusWriter {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func deliver(_ rec: ReplayAccessPolicyStatusRecord) async throws {
        let request = Acme_Telehealth_V1_TerminateTriageRequest.with {
            $0.triageID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.terminateTriage(request)
        }
    }
}

/// Passes records to acme.notifications.v1.NotificationQueryService.
struct ReplayAccessPolicyStatusNotificationQuery: ReplayAccessPolicyStatusWriter {
    let client: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>

    func deliver(_ rec: ReplayAccessPolicyStatusRecord) async throws {
        _ = try await client.countNotifications(.with {
            $0.page.pageToken = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayAccessPolicyStatusLogOnly: ReplayAccessPolicyStatusWriter {
    let logger = Logger(label: "acme.replay-access-policy-status")

    func deliver(_ rec: ReplayAccessPolicyStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.authorization.v1.AccessPolicyService/DeleteAccessPolicy and hands what it keeps to the sink of its kind.
enum ReplayAccessPolicyStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)
        let got = try await reader.deleteAccessPolicy(.with { $0.reason = "main-replay-access-policy-status" })
        let row = ReplayAccessPolicyStatusRecord(
            status: got.result.status,
            message: got.result.message
        )
        try await dispatch("triage-lifecycle", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: ReplayAccessPolicyStatusRecord, _ mesh: MeshClient) async throws {
        var write: (ReplayAccessPolicyStatusRecord) async throws -> Void = ReplayAccessPolicyStatusLogOnly().deliver
        switch kind {
        case "yard-calculation":
            write = ReplayAccessPolicyStatusYardCalculation(client: Acme_Yards_V1_YardCalculationService.Client(wrapping: mesh)).deliver
        case "triage-lifecycle":
            write = ReplayAccessPolicyStatusTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)).deliver
        case "notification-query":
            write = ReplayAccessPolicyStatusNotificationQuery(client: Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)).deliver
        default:
            break
        }
        try await write(rec)
    }
}
