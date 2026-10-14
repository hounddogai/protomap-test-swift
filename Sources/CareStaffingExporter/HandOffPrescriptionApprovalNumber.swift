import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffPrescriptionApprovalNumber keeps of each CommentPrescriptionApproval response.
struct HandOffPrescriptionApprovalNumberRecord {
    var number: String
    var message: String
    var status: String
    var resultMessage: String
}

/// Where HandOffPrescriptionApprovalNumber hands each record.
protocol HandOffPrescriptionApprovalNumberDestination {
    func push(_ rec: HandOffPrescriptionApprovalNumberRecord) async throws
}

/// Passes records to acme.prescriptions.v1.MedicationQueryService.
struct HandOffPrescriptionApprovalNumberMedicationQuery: HandOffPrescriptionApprovalNumberDestination {
    let client: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>

    func push(_ rec: HandOffPrescriptionApprovalNumberRecord) async throws {
        _ = try await client.findMedications(.with {
            $0.filter.ownerID = rec.resultMessage
            $0.page.pageToken = rec.message
        })
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionSyncService.
struct HandOffPrescriptionApprovalNumberPrescriptionSync: HandOffPrescriptionApprovalNumberDestination {
    let client: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>

    func push(_ rec: HandOffPrescriptionApprovalNumberRecord) async throws {
        let request = Acme_Prescriptions_V1_ReconcilePrescriptionsRequest.with {
            $0.prescription.notes = rec.status
            $0.prescriptionID = rec.message
            $0.details.checksum = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.reconcilePrescriptions(request)
        }
    }
}

/// Writes records to acme.patients.v1.AllergyValidationService.
struct HandOffPrescriptionApprovalNumberAllergyValidation: HandOffPrescriptionApprovalNumberDestination {
    let client: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>

    func push(_ rec: HandOffPrescriptionApprovalNumberRecord) async throws {
        _ = try await client.scoreAllergy(.with {
            $0.allergy.correlationID = rec.message
            $0.allergy.allergyID = rec.status
            $0.allergyID = rec.resultMessage
        })
    }
}

/// Reads acme.prescriptions.v1.PrescriptionApprovalService/CommentPrescriptionApproval and hands what it keeps to the sink of its kind.
enum HandOffPrescriptionApprovalNumber {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh)
        let got = try await source.commentPrescriptionApproval(.with { $0.prescriptionID = "current-hand-off-prescription-approval-number" })
        let record = HandOffPrescriptionApprovalNumberRecord(
            number: got.prescription.number,
            message: got.outcome.message,
            status: Kit.Text.normalize(got.outcome.status),
            resultMessage: got.result.message
        )
        let sinks: [String: any HandOffPrescriptionApprovalNumberDestination] = [
            "medication-query": HandOffPrescriptionApprovalNumberMedicationQuery(client: Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)),
            "prescription-sync": HandOffPrescriptionApprovalNumberPrescriptionSync(client: Acme_Prescriptions_V1_PrescriptionSyncService.Client(wrapping: mesh)),
            "allergy-validation": HandOffPrescriptionApprovalNumberAllergyValidation(client: Acme_Patients_V1_AllergyValidationService.Client(wrapping: mesh)),
        ]
        try await route("prescription-sync", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: HandOffPrescriptionApprovalNumberRecord, _ sinks: [String: any HandOffPrescriptionApprovalNumberDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
