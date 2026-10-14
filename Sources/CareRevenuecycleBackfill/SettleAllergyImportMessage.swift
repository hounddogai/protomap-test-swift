import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleAllergyImportMessage keeps of each CancelAllergyImport response.
struct SettleAllergyImportMessageRecord {
    var message: String
    var allergyID: String
}

/// Where SettleAllergyImportMessage hands each record.
protocol SettleAllergyImportMessageTarget {
    func apply(_ rec: SettleAllergyImportMessageRecord) async throws
}

/// Writes records to acme.audit.v1.AuditEventValidationService.
struct SettleAllergyImportMessageAuditEventValidation: SettleAllergyImportMessageTarget {
    let client: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>

    func apply(_ rec: SettleAllergyImportMessageRecord) async throws {
        _ = try await client.previewAuditEvent(.with {
            $0.auditEvent.correlationID = rec.message
        })
    }
}

/// Sends records to acme.tours.v1.TourQueryService.
struct SettleAllergyImportMessageTourQuery: SettleAllergyImportMessageTarget {
    let client: Acme_Tours_V1_TourQueryService.Client<MeshTransport>

    func apply(_ rec: SettleAllergyImportMessageRecord) async throws {
        _ = try await client.findTours(.with {
            $0.filter.ownerID = rec.message
            $0.filter.query = rec.allergyID
        })
    }
}

/// Writes records to acme.patients.v1.PatientWorkflowService.
struct SettleAllergyImportMessagePatientWorkflow: SettleAllergyImportMessageTarget {
    let client: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>

    func apply(_ rec: SettleAllergyImportMessageRecord) async throws {
        _ = try await client.cancelPatientWorkflow(.with {
            $0.reason = rec.message
        })
    }
}

/// Reads acme.patients.v1.AllergyImportService/CancelAllergyImport and hands what it keeps to the sink of its kind.
enum SettleAllergyImportMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_AllergyImportService.Client(wrapping: mesh)
        let got = try await reader.cancelAllergyImport(.with { $0.reason = "default-settle-allergy-import-message" })
        let row = SettleAllergyImportMessageRecord(
            message: got.outcome.message,
            allergyID: got.allergy.allergyID
        )
        let sinks: [String: any SettleAllergyImportMessageTarget] = [
            "audit-event-validation": SettleAllergyImportMessageAuditEventValidation(client: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: mesh)),
            "tour-query": SettleAllergyImportMessageTourQuery(client: Acme_Tours_V1_TourQueryService.Client(wrapping: mesh)),
            "patient-workflow": SettleAllergyImportMessagePatientWorkflow(client: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["SETTLE_ALLERGY_IMPORT_MESSAGE_TARGET"] ?? ""] else {
            return
        }
        try await sink.apply(row)
    }
}
