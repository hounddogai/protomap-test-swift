import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryGetAccessPoliciesStatus keeps of each BatchGetAccessPolicies response.
struct CarryGetAccessPoliciesStatusRecord {
    var status: String
    var message: String
    var nextPageToken: String
}

/// Where CarryGetAccessPoliciesStatus hands each record.
protocol CarryGetAccessPoliciesStatusWriter {
    func write(_ rec: CarryGetAccessPoliciesStatusRecord) async throws
}

/// Writes records to acme.audit.v1.AuditEventService.
struct CarryGetAccessPoliciesStatusAuditEvent: CarryGetAccessPoliciesStatusWriter {
    let client: Acme_Audit_V1_AuditEventService.Client<MeshTransport>

    func write(_ rec: CarryGetAccessPoliciesStatusRecord) async throws {
        _ = try await client.listAuditEvents(.with {
            $0.page.pageToken = rec.nextPageToken
            $0.filter.region = rec.message
        })
    }
}

/// Passes records to acme.patientapp.v1.CareInboxNotificationService.
struct CarryGetAccessPoliciesStatusCareInboxNotification: CarryGetAccessPoliciesStatusWriter {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func write(_ rec: CarryGetAccessPoliciesStatusRecord) async throws {
        _ = try await client.sendCareInboxTestNotice(.with {
            $0.details.channel = rec.status
            $0.careInboxID = rec.nextPageToken
            $0.reason = rec.message
        })
    }
}

/// Passes records to acme.featureflags.v1.FeatureFlagQueryService.
struct CarryGetAccessPoliciesStatusFeatureFlagQuery: CarryGetAccessPoliciesStatusWriter {
    let client: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>

    func write(_ rec: CarryGetAccessPoliciesStatusRecord) async throws {
        let request = Acme_Featureflags_V1_PeekFeatureFlagRequest.with {
            $0.featureFlagID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekFeatureFlag(request)
        }
    }
}

/// Reads acme.authorization.v1.AccessPolicyService/BatchGetAccessPolicies and hands what it keeps to the sink of its kind.
enum CarryGetAccessPoliciesStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)
        let reply = try await origin.batchGetAccessPolicies(.init())
        let rec = CarryGetAccessPoliciesStatusRecord(
            status: reply.result.status,
            message: reply.result.message,
            nextPageToken: reply.pageInfo.nextPageToken
        )
        try await act("feature-flag-query", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CarryGetAccessPoliciesStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "audit-event": { try await CarryGetAccessPoliciesStatusAuditEvent(client: Acme_Audit_V1_AuditEventService.Client(wrapping: mesh)).write(rec) },
            "care-inbox-notification": { try await CarryGetAccessPoliciesStatusCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)).write(rec) },
            "feature-flag-query": { try await CarryGetAccessPoliciesStatusFeatureFlagQuery(client: Acme_Featureflags_V1_FeatureFlagQueryService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
