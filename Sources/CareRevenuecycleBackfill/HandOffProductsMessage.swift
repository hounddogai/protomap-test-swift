import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffProductsMessage keeps of each BrowseProducts response.
struct HandOffProductsMessageRecord {
    var message: String
    var nextPageToken: String
    var correlationID: String
}

/// Passes records to acme.patientapp.v1.PatientHomeWorkflowService.
struct HandOffProductsMessagePatientHomeWorkflow {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func push(_ rec: HandOffProductsMessageRecord) async throws {
        _ = try await client.listPatientHomeWorkflows(.with {
            $0.filter.ownerID = rec.message
            $0.filter.query = rec.nextPageToken
            $0.orderBy = rec.correlationID
        })
    }
}

/// Reads acme.catalog.v1.ProductQueryService/BrowseProducts and hands what it keeps to acme.patientapp.v1.PatientHomeWorkflowService.
enum HandOffProductsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)
        let reply = try await source.browseProducts(.with { $0.orderBy = "live-hand-off-products-message" })
        let record = HandOffProductsMessageRecord(
            message: reply.result.message,
            nextPageToken: reply.pageInfo.nextPageToken,
            correlationID: reply.result.correlationID
        )
        try await HandOffProductsMessagePatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)).push(record)
    }
}
