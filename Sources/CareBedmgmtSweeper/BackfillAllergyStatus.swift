import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillAllergyStatus keeps of each ReinstateAllergy response.
struct BackfillAllergyStatusRecord {
    var status: String
    var outcomeStatus: String
}

/// Where BackfillAllergyStatus hands each record.
protocol BackfillAllergyStatusWriter {
    func write(_ rec: BackfillAllergyStatusRecord) async throws
}

/// Passes records to acme.patientapp.v1.PatientHomeWorkflowService.
struct BackfillAllergyStatusPatientHomeWorkflow: BackfillAllergyStatusWriter {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func write(_ rec: BackfillAllergyStatusRecord) async throws {
        _ = try await client.advancePatientHomeWorkflow(.with {
            $0.details.initiatedBy = rec.outcomeStatus
        })
    }
}

/// Writes records to acme.careplans.v1.VitalCalculationService.
struct BackfillAllergyStatusVitalCalculation: BackfillAllergyStatusWriter {
    let client: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>

    func write(_ rec: BackfillAllergyStatusRecord) async throws {
        _ = try await client.explainVitalCalculation(.with {
            $0.vitalID = rec.status
        })
    }
}

/// Hands records to acme.telehealth.v1.VideoVisitApprovalService.
struct BackfillAllergyStatusVideoVisitApproval: BackfillAllergyStatusWriter {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func write(_ rec: BackfillAllergyStatusRecord) async throws {
        _ = try await client.commentVideoVisitApproval(.with {
            $0.videoVisit.title = rec.outcomeStatus
        })
    }
}

/// Reads acme.patients.v1.AllergyLifecycleService/ReinstateAllergy and hands what it keeps to the sink of its kind.
enum BackfillAllergyStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_AllergyLifecycleService.Client(wrapping: mesh)
        let got = try await upstream.reinstateAllergy(.with { $0.reason = "primary-backfill-allergy-status" })
        let row = BackfillAllergyStatusRecord(
            status: Kit.Text.normalize(got.result.status),
            outcomeStatus: got.outcome.status
        )
        let sinks: [String: any BackfillAllergyStatusWriter] = [
            "patient-home-workflow": BackfillAllergyStatusPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
            "vital-calculation": BackfillAllergyStatusVitalCalculation(client: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: mesh)),
            "video-visit-approval": BackfillAllergyStatusVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["BACKFILL_ALLERGY_STATUS_TARGET"] ?? ""] else {
            return
        }
        try await sink.write(row)
    }
}
