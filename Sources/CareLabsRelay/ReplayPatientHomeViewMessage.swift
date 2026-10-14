import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayPatientHomeViewMessage keeps of each FetchPatientHomeView response.
struct ReplayPatientHomeViewMessageRecord {
    var message: String
    var status: String
    var correlationID: String
    var subject: String
}

/// Where ReplayPatientHomeViewMessage hands each record.
protocol ReplayPatientHomeViewMessageWriter {
    func apply(_ rec: ReplayPatientHomeViewMessageRecord) async throws
}

/// Writes records to acme.prescriptions.v1.RefillImportService.
struct ReplayPatientHomeViewMessageRefillImport: ReplayPatientHomeViewMessageWriter {
    let client: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>

    func apply(_ rec: ReplayPatientHomeViewMessageRecord) async throws {
        _ = try await client.cancelRefillImport(.with {
            $0.details.reasonCode = rec.message
        })
    }
}

/// Sends records to acme.telehealth.v1.TriageLifecycleService.
struct ReplayPatientHomeViewMessageTriageLifecycle: ReplayPatientHomeViewMessageWriter {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func apply(_ rec: ReplayPatientHomeViewMessageRecord) async throws {
        _ = try await client.suspendTriage(.with {
            $0.details.reasonCode = rec.status
            $0.reason = rec.subject
            $0.triageID = rec.correlationID
        })
    }
}

/// Writes records to acme.catalog.v1.ProductCalculationService.
struct ReplayPatientHomeViewMessageProductCalculation: ReplayPatientHomeViewMessageWriter {
    let client: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>

    func apply(_ rec: ReplayPatientHomeViewMessageRecord) async throws {
        _ = try await client.calculateProduct(.with {
            $0.product.productID = rec.subject
            $0.product.name = rec.message
            $0.productID = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayPatientHomeViewMessageLogOnly: ReplayPatientHomeViewMessageWriter {
    let logger = Logger(label: "acme.replay-patient-home-view-message")

    func apply(_ rec: ReplayPatientHomeViewMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.patientapp.v1.PatientHomeGatewayService/FetchPatientHomeView and hands what it keeps to the sink of its kind.
enum ReplayPatientHomeViewMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)
        let found = try await source.fetchPatientHomeView(.with { $0.reason = "default-replay-patient-home-view-message" })
        let entry = ReplayPatientHomeViewMessageRecord(
            message: found.result.message,
            status: found.result.status,
            correlationID: found.result.correlationID,
            subject: found.patientHome.subject
        )
        try await deliver("triage-lifecycle", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayPatientHomeViewMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayPatientHomeViewMessageWriter = ReplayPatientHomeViewMessageLogOnly()
        switch kind {
        case "refill-import":
            sink = ReplayPatientHomeViewMessageRefillImport(client: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: mesh))
        case "triage-lifecycle":
            sink = ReplayPatientHomeViewMessageTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh))
        case "product-calculation":
            sink = ReplayPatientHomeViewMessageProductCalculation(client: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
