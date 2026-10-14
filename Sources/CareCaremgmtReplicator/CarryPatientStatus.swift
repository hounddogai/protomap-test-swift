import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryPatientStatus keeps of each EscalatePatient response.
struct CarryPatientStatusRecord {
    var status: String
    var message: String
    var patientID: String
    var referenceID: String
}

/// Where CarryPatientStatus hands each record.
protocol CarryPatientStatusSink {
    func apply(_ rec: CarryPatientStatusRecord) async throws
}

/// Sends records to acme.patients.v1.PatientWorkflowService.
struct CarryPatientStatusPatientWorkflow: CarryPatientStatusSink {
    let client: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>

    func apply(_ rec: CarryPatientStatusRecord) async throws {
        _ = try await client.cancelPatientWorkflow(.with {
            $0.details.step = rec.referenceID
        })
    }
}

/// Hands records to acme.catalog.v1.ProductQueryService.
struct CarryPatientStatusProductQuery: CarryPatientStatusSink {
    let client: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>

    func apply(_ rec: CarryPatientStatusRecord) async throws {
        let request = Acme_Catalog_V1_LookupProductRequest.with {
            $0.productID = rec.patientID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupProduct(request)
        }
    }
}

/// Reads acme.patients.v1.PatientApprovalService/EscalatePatient and hands what it keeps to the sink of its kind.
enum CarryPatientStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)
        let reply = try await upstream.escalatePatient(.with { $0.reason = "current-carry-patient-status" })
        let rec = CarryPatientStatusRecord(
            status: reply.outcome.status,
            message: reply.outcome.message,
            patientID: reply.patient.patientID,
            referenceID: reply.outcome.referenceID
        )
        try await act("product-query", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CarryPatientStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "patient-workflow": { try await CarryPatientStatusPatientWorkflow(client: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: mesh)).apply(rec) },
            "product-query": { try await CarryPatientStatusProductQuery(client: Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
