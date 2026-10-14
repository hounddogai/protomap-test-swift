import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarrySearchIndexesID keeps of each CountSearchIndexes response.
struct CarrySearchIndexesIDRecord {
    var correlationID: String
    var status: String
}

/// Where CarrySearchIndexesID hands each record.
protocol CarrySearchIndexesIDSink {
    func send(_ rec: CarrySearchIndexesIDRecord) async throws
}

/// Passes records to acme.patientapp.v1.CareInboxWorkflowService.
struct CarrySearchIndexesIDCareInboxWorkflow: CarrySearchIndexesIDSink {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func send(_ rec: CarrySearchIndexesIDRecord) async throws {
        let request = Acme_Patientapp_V1_RetryCareInboxWorkflowRequest.with {
            $0.careInbox.number = rec.correlationID
            $0.details.initiatedBy = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.retryCareInboxWorkflow(request)
        }
    }
}

/// Passes records to acme.tours.v1.TourService.
struct CarrySearchIndexesIDTour: CarrySearchIndexesIDSink {
    let client: Acme_Tours_V1_TourService.Client<MeshTransport>

    func send(_ rec: CarrySearchIndexesIDRecord) async throws {
        _ = try await client.deleteTour(.with {
            $0.tourID = rec.status
        })
    }
}

/// Reads acme.search.v1.SearchIndexQueryService/CountSearchIndexes and hands what it keeps to the sink of its kind.
enum CarrySearchIndexesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Search_V1_SearchIndexQueryService.Client(wrapping: mesh)
        let response = try await origin.countSearchIndexes(.with { $0.orderBy = "primary-carry-search-indexes-id" })
        let rec = CarrySearchIndexesIDRecord(
            correlationID: response.result.correlationID,
            status: Kit.Text.normalize(response.result.status)
        )
        let sinks: [any CarrySearchIndexesIDSink] = [
            CarrySearchIndexesIDCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)),
            CarrySearchIndexesIDTour(client: Acme_Tours_V1_TourService.Client(wrapping: mesh)),
        ]
        try await sinks[0].send(rec)
    }
}
