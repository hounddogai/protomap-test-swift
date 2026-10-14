import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyAccessPoliciesMessage keeps of each BrowseAccessPolicies response.
struct CopyAccessPoliciesMessageRecord {
    var message: String
    var correlationID: String
    var status: String
    var nextPageToken: String
}

/// Where CopyAccessPoliciesMessage hands each record.
protocol CopyAccessPoliciesMessageTarget {
    func deliver(_ rec: CopyAccessPoliciesMessageRecord) async throws
}

/// Writes records to acme.anomalies.v1.AnomalyQueryService.
struct CopyAccessPoliciesMessageAnomalyQuery: CopyAccessPoliciesMessageTarget {
    let client: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>

    func deliver(_ rec: CopyAccessPoliciesMessageRecord) async throws {
        _ = try await client.countAnomalies(.with {
            $0.filter.query = rec.status
            $0.orderBy = rec.correlationID
        })
    }
}

/// Sends records to acme.prescriptions.v1.RefillValidationService.
struct CopyAccessPoliciesMessageRefillValidation: CopyAccessPoliciesMessageTarget {
    let client: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>

    func deliver(_ rec: CopyAccessPoliciesMessageRecord) async throws {
        _ = try await client.normalizeRefill(.with {
            $0.refillID = rec.nextPageToken
            $0.refill.refillID = rec.message
        })
    }
}

/// Reads acme.authorization.v1.AccessPolicyQueryService/BrowseAccessPolicies and hands what it keeps to the sink of its kind.
enum CopyAccessPoliciesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Authorization_V1_AccessPolicyQueryService.Client(wrapping: mesh)
        let got = try await origin.browseAccessPolicies(.with { $0.orderBy = "nightly-copy-access-policies-message" })
        let entry = CopyAccessPoliciesMessageRecord(
            message: got.result.message,
            correlationID: got.result.correlationID,
            status: Kit.Text.normalize(got.result.status),
            nextPageToken: got.pageInfo.nextPageToken
        )
        let sinks: [String: any CopyAccessPoliciesMessageTarget] = [
            "anomaly-query": CopyAccessPoliciesMessageAnomalyQuery(client: Acme_Anomalies_V1_AnomalyQueryService.Client(wrapping: mesh)),
            "refill-validation": CopyAccessPoliciesMessageRefillValidation(client: Acme_Prescriptions_V1_RefillValidationService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["COPY_ACCESS_POLICIES_MESSAGE_TARGET"] ?? ""] else {
            return
        }
        try await sink.deliver(entry)
    }
}
