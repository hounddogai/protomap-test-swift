import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyProvidersStatus keeps of each LintProviders response.
struct CopyProvidersStatusRecord {
    var status: String
    var providerID: String
    var correlationID: String
    var message: String
}

/// Where CopyProvidersStatus hands each record.
protocol CopyProvidersStatusSink {
    func write(_ rec: CopyProvidersStatusRecord) async throws
}

/// Passes records to acme.telehealth.v1.VideoVisitWorkflowService.
struct CopyProvidersStatusVideoVisitWorkflow: CopyProvidersStatusSink {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func write(_ rec: CopyProvidersStatusRecord) async throws {
        _ = try await client.signalVideoVisitWorkflow(.with {
            $0.details.step = rec.status
            $0.videoVisit.videoVisitID = rec.message
            $0.details.initiatedBy = rec.providerID
        })
    }
}

/// Writes records to acme.catalog.v1.ProductCalculationService.
struct CopyProvidersStatusProductCalculation: CopyProvidersStatusSink {
    let client: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>

    func write(_ rec: CopyProvidersStatusRecord) async throws {
        let request = Acme_Catalog_V1_CompareProductOptionsRequest.with {
            $0.product.productID = rec.status
            $0.product.code = rec.providerID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareProductOptions(request)
        }
    }
}

/// Sends records to acme.admissions.v1.AdmissionQueryService.
struct CopyProvidersStatusAdmissionQuery: CopyProvidersStatusSink {
    let client: Acme_Admissions_V1_AdmissionQueryService.Client<MeshTransport>

    func write(_ rec: CopyProvidersStatusRecord) async throws {
        let request = Acme_Admissions_V1_LookupAdmissionRequest.with {
            $0.admissionID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupAdmission(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct CopyProvidersStatusLogOnly: CopyProvidersStatusSink {
    let logger = Logger(label: "acme.copy-providers-status")

    func write(_ rec: CopyProvidersStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.appointments.v1.ProviderValidationService/LintProviders and hands what it keeps to the sink of its kind.
enum CopyProvidersStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Appointments_V1_ProviderValidationService.Client(wrapping: mesh)
        let response = try await origin.lintProviders(.with { $0.providerID = "live-copy-providers-status" })
        let row = CopyProvidersStatusRecord(
            status: response.outcome.status,
            providerID: response.provider.providerID,
            correlationID: response.result.correlationID,
            message: response.result.message
        )
        try await deliver("product-calculation", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CopyProvidersStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any CopyProvidersStatusSink = CopyProvidersStatusLogOnly()
        switch kind {
        case "video-visit-workflow":
            sink = CopyProvidersStatusVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh))
        case "product-calculation":
            sink = CopyProvidersStatusProductCalculation(client: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh))
        case "admission-query":
            sink = CopyProvidersStatusAdmissionQuery(client: Acme_Admissions_V1_AdmissionQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
