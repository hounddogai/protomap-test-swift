import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryConcessionStandsStatus keeps of each SuggestConcessionStands response.
struct CarryConcessionStandsStatusRecord {
    var status: String
    var nextPageToken: String
    var correlationID: String
    var message: String
}

/// Where CarryConcessionStandsStatus hands each record.
protocol CarryConcessionStandsStatusTarget {
    func send(_ rec: CarryConcessionStandsStatusRecord) async throws
}

/// Hands records to acme.search.v1.SearchIndexValidationService.
struct CarryConcessionStandsStatusSearchIndexValidation: CarryConcessionStandsStatusTarget {
    let client: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>

    func send(_ rec: CarryConcessionStandsStatusRecord) async throws {
        _ = try await client.normalizeSearchIndex(.with {
            $0.details.locale = rec.status
            $0.searchIndex.searchIndexID = rec.message
            $0.searchIndexID = rec.correlationID
        })
    }
}

/// Passes records to acme.appointments.v1.ProviderWorkflowService.
struct CarryConcessionStandsStatusProviderWorkflow: CarryConcessionStandsStatusTarget {
    let client: Acme_Appointments_V1_ProviderWorkflowService.Client<MeshTransport>

    func send(_ rec: CarryConcessionStandsStatusRecord) async throws {
        let request = Acme_Appointments_V1_CancelProviderWorkflowRequest.with {
            $0.details.initiatedBy = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.cancelProviderWorkflow(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct CarryConcessionStandsStatusLogOnly: CarryConcessionStandsStatusTarget {
    let logger = Logger(label: "acme.carry-concession-stands-status")

    func send(_ rec: CarryConcessionStandsStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.concessions.v1.ConcessionStandQueryService/SuggestConcessionStands and hands what it keeps to the sink of its kind.
enum CarryConcessionStandsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Concessions_V1_ConcessionStandQueryService.Client(wrapping: mesh)
        let response = try await reader.suggestConcessionStands(.with { $0.orderBy = "primary-carry-concession-stands-status" })
        let record = CarryConcessionStandsStatusRecord(
            status: response.result.status,
            nextPageToken: Kit.Text.normalize(response.pageInfo.nextPageToken),
            correlationID: response.result.correlationID,
            message: response.result.message
        )
        try await deliver("provider-workflow", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CarryConcessionStandsStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any CarryConcessionStandsStatusTarget = CarryConcessionStandsStatusLogOnly()
        switch kind {
        case "search-index-validation":
            sink = CarryConcessionStandsStatusSearchIndexValidation(client: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh))
        case "provider-workflow":
            sink = CarryConcessionStandsStatusProviderWorkflow(client: Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
