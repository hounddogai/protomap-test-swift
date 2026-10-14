import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorMedicalRecordDecisionID keeps of each ExplainMedicalRecordDecision response.
struct MirrorMedicalRecordDecisionIDRecord {
    var referenceID: String
    var status: String
}

/// Passes records to acme.careplans.v1.VitalApprovalService.
struct MirrorMedicalRecordDecisionIDVitalApproval {
    let client: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>

    func push(_ rec: MirrorMedicalRecordDecisionIDRecord) async throws {
        _ = try await client.commentVitalApproval(.with {
            $0.details.comment = rec.status
            $0.vital.correlationID = rec.referenceID
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordValidationService/ExplainMedicalRecordDecision and hands what it keeps to acme.careplans.v1.VitalApprovalService.
enum MirrorMedicalRecordDecisionID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_MedicalRecordValidationService.Client(wrapping: mesh)
        let reply = try await origin.explainMedicalRecordDecision(.with { $0.medicalRecordID = "main-mirror-medical-record-decision-id" })
        let entry = MirrorMedicalRecordDecisionIDRecord(
            referenceID: reply.outcome.referenceID,
            status: reply.outcome.status
        )
        try await MirrorMedicalRecordDecisionIDVitalApproval(client: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)).push(entry)
    }
}
