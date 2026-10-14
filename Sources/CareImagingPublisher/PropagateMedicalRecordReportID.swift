import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateMedicalRecordReportID keeps of each ShareMedicalRecordReport response.
struct PropagateMedicalRecordReportIDRecord {
    var medicalRecordID: String
    var referenceID: String
    var status: String
    var message: String
}

/// Where PropagateMedicalRecordReportID hands each record.
protocol PropagateMedicalRecordReportIDSink {
    func send(_ rec: PropagateMedicalRecordReportIDRecord) async throws
}

/// Hands records to acme.telehealth.v1.TriageValidationService.
struct PropagateMedicalRecordReportIDTriageValidation: PropagateMedicalRecordReportIDSink {
    let client: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordReportIDRecord) async throws {
        _ = try await client.getTriageRules(.with {
            $0.triageID = rec.message
        })
    }
}

/// Hands records to acme.careplans.v1.CareGoalCalculationService.
struct PropagateMedicalRecordReportIDCareGoalCalculation: PropagateMedicalRecordReportIDSink {
    let client: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordReportIDRecord) async throws {
        _ = try await client.recalculateCareGoals(.with {
            $0.reason = rec.referenceID
            $0.careGoal.subject = rec.status
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordReportingService/ShareMedicalRecordReport and hands what it keeps to the sink of its kind.
enum PropagateMedicalRecordReportID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_MedicalRecordReportingService.Client(wrapping: mesh)
        let response = try await origin.shareMedicalRecordReport(.with { $0.medicalRecordID = "live-propagate-medical-record-report-id" })
        let record = PropagateMedicalRecordReportIDRecord(
            medicalRecordID: response.medicalRecord.medicalRecordID,
            referenceID: response.outcome.referenceID,
            status: response.result.status,
            message: response.result.message
        )
        try await act("care-goal-calculation", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: PropagateMedicalRecordReportIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "triage-validation": { try await PropagateMedicalRecordReportIDTriageValidation(client: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: mesh)).send(rec) },
            "care-goal-calculation": { try await PropagateMedicalRecordReportIDCareGoalCalculation(client: Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
