import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffPatientConflictsMessage keeps of each ListPatientConflicts response.
struct HandOffPatientConflictsMessageRecord {
    var message: String
    var correlationID: String
}

/// Where HandOffPatientConflictsMessage hands each record.
protocol HandOffPatientConflictsMessageWriter {
    func apply(_ rec: HandOffPatientConflictsMessageRecord) async throws
}

/// Passes records to acme.patients.v1.AllergyWorkflowService.
struct HandOffPatientConflictsMessageAllergyWorkflow: HandOffPatientConflictsMessageWriter {
    let client: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>

    func apply(_ rec: HandOffPatientConflictsMessageRecord) async throws {
        let request = Acme_Patients_V1_ListAllergyWorkflowsRequest.with {
            $0.filter.region = rec.correlationID
            $0.page.pageToken = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listAllergyWorkflows(request)
        }
    }
}

/// Passes records to acme.patients.v1.AllergyImportService.
struct HandOffPatientConflictsMessageAllergyImport: HandOffPatientConflictsMessageWriter {
    let client: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>

    func apply(_ rec: HandOffPatientConflictsMessageRecord) async throws {
        let request = Acme_Patients_V1_ListAllergyImportsRequest.with {
            $0.filter.ownerID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listAllergyImports(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct HandOffPatientConflictsMessageLogOnly: HandOffPatientConflictsMessageWriter {
    let logger = Logger(label: "acme.hand-off-patient-conflicts-message")

    func apply(_ rec: HandOffPatientConflictsMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.patients.v1.PatientSyncService/ListPatientConflicts and hands what it keeps to the sink of its kind.
enum HandOffPatientConflictsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_PatientSyncService.Client(wrapping: mesh)
        let got = try await source.listPatientConflicts(.with { $0.orderBy = "primary-hand-off-patient-conflicts-message" })
        let entry = HandOffPatientConflictsMessageRecord(
            message: Kit.Text.normalize(got.result.message),
            correlationID: got.result.correlationID
        )
        try await deliver("allergy-import", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: HandOffPatientConflictsMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any HandOffPatientConflictsMessageWriter = HandOffPatientConflictsMessageLogOnly()
        switch kind {
        case "allergy-workflow":
            sink = HandOffPatientConflictsMessageAllergyWorkflow(client: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh))
        case "allergy-import":
            sink = HandOffPatientConflictsMessageAllergyImport(client: Acme_Patients_V1_AllergyImportService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
