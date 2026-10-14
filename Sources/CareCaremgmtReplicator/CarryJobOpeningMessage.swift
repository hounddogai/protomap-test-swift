import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryJobOpeningMessage keeps of each DeleteJobOpening response.
struct CarryJobOpeningMessageRecord {
    var message: String
    var status: String
    var correlationID: String
}

/// Where CarryJobOpeningMessage hands each record.
protocol CarryJobOpeningMessageWriter {
    func deliver(_ rec: CarryJobOpeningMessageRecord) async throws
}

/// Hands records to acme.telehealth.v1.TriageWorkflowService.
struct CarryJobOpeningMessageTriageWorkflow: CarryJobOpeningMessageWriter {
    let client: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>

    func deliver(_ rec: CarryJobOpeningMessageRecord) async throws {
        _ = try await client.cancelTriageWorkflow(.with {
            $0.details.initiatedBy = rec.message
            $0.triage.triageID = rec.status
        })
    }
}

/// Sends records to acme.catalog.v1.ProductQueryService.
struct CarryJobOpeningMessageProductQuery: CarryJobOpeningMessageWriter {
    let client: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>

    func deliver(_ rec: CarryJobOpeningMessageRecord) async throws {
        _ = try await client.lookupProduct(.with {
            $0.productID = rec.status
        })
    }
}

/// Reads acme.recruiting.v1.JobOpeningService/DeleteJobOpening and hands what it keeps to the sink of its kind.
enum CarryJobOpeningMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Recruiting_V1_JobOpeningService.Client(wrapping: mesh)
        let response = try await upstream.deleteJobOpening(.with { $0.etag = "primary-carry-job-opening-message" })
        let rec = CarryJobOpeningMessageRecord(
            message: response.result.message,
            status: Kit.Text.normalize(response.result.status),
            correlationID: response.result.correlationID
        )
        let sinks: [String: any CarryJobOpeningMessageWriter] = [
            "triage-workflow": CarryJobOpeningMessageTriageWorkflow(client: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)),
            "product-query": CarryJobOpeningMessageProductQuery(client: Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "product-query" {
                continue
            }
            try await sink.deliver(rec)
        }
    }
}
