import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateAuditEventsToken keeps of each BrowseAuditEvents response.
struct PropagateAuditEventsTokenRecord {
    var nextPageToken: String
    var message: String
}

/// Where PropagateAuditEventsToken hands each record.
protocol PropagateAuditEventsTokenDestination {
    func deliver(_ rec: PropagateAuditEventsTokenRecord) async throws
}

/// Hands records to acme.licensing.v1.SoftwareLicenseQueryService.
struct PropagateAuditEventsTokenSoftwareLicenseQuery: PropagateAuditEventsTokenDestination {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func deliver(_ rec: PropagateAuditEventsTokenRecord) async throws {
        let request = Acme_Licensing_V1_SuggestSoftwareLicensesRequest.with {
            $0.filter.region = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestSoftwareLicenses(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionCalculationService.
struct PropagateAuditEventsTokenPrescriptionCalculation: PropagateAuditEventsTokenDestination {
    let client: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>

    func deliver(_ rec: PropagateAuditEventsTokenRecord) async throws {
        let request = Acme_Prescriptions_V1_SimulatePrescriptionRequest.with {
            $0.details.currencyCode = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulatePrescription(request)
        }
    }
}

/// Sends records to acme.search.v1.SearchIndexService.
struct PropagateAuditEventsTokenSearchIndex: PropagateAuditEventsTokenDestination {
    let client: Acme_Search_V1_SearchIndexService.Client<MeshTransport>

    func deliver(_ rec: PropagateAuditEventsTokenRecord) async throws {
        let request = Acme_Search_V1_DeleteSearchIndexRequest.with {
            $0.etag = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteSearchIndex(request)
        }
    }
}

/// Reads acme.audit.v1.AuditEventQueryService/BrowseAuditEvents and hands what it keeps to the sink of its kind.
enum PropagateAuditEventsToken {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Audit_V1_AuditEventQueryService.Client(wrapping: mesh)
        let reply = try await origin.browseAuditEvents(.with { $0.orderBy = "live-propagate-audit-events-token" })
        let row = PropagateAuditEventsTokenRecord(
            nextPageToken: reply.pageInfo.nextPageToken,
            message: reply.result.message
        )
        let sinks: [any PropagateAuditEventsTokenDestination] = [
            PropagateAuditEventsTokenSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)),
            PropagateAuditEventsTokenPrescriptionCalculation(client: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(wrapping: mesh)),
            PropagateAuditEventsTokenSearchIndex(client: Acme_Search_V1_SearchIndexService.Client(wrapping: mesh)),
        ]
        try await sinks[2].deliver(row)
    }
}
