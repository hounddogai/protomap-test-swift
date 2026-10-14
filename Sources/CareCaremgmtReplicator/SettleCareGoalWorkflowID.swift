import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleCareGoalWorkflowID keeps of each CancelCareGoalWorkflow response.
struct SettleCareGoalWorkflowIDRecord {
    var referenceID: String
    var careGoalID: String
}

/// Where SettleCareGoalWorkflowID hands each record.
protocol SettleCareGoalWorkflowIDTarget {
    func write(_ rec: SettleCareGoalWorkflowIDRecord) async throws
}

/// Sends records to acme.prescriptions.v1.MedicationValidationService.
struct SettleCareGoalWorkflowIDMedicationValidation: SettleCareGoalWorkflowIDTarget {
    let client: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>

    func write(_ rec: SettleCareGoalWorkflowIDRecord) async throws {
        _ = try await client.checkMedicationEligibility(.with {
            $0.reason = rec.referenceID
            $0.medication.medicationID = rec.careGoalID
        })
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteValidationService.
struct SettleCareGoalWorkflowIDVisitNoteValidation: SettleCareGoalWorkflowIDTarget {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func write(_ rec: SettleCareGoalWorkflowIDRecord) async throws {
        _ = try await client.lintVisitNotes(.with {
            $0.visitNote.number = rec.referenceID
        })
    }
}

/// Reads acme.careplans.v1.CareGoalWorkflowService/CancelCareGoalWorkflow and hands what it keeps to the sink of its kind.
enum SettleCareGoalWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh)
        let reply = try await upstream.cancelCareGoalWorkflow(.with { $0.careGoalID = "current-settle-care-goal-workflow-id" })
        let row = SettleCareGoalWorkflowIDRecord(
            referenceID: reply.outcome.referenceID,
            careGoalID: reply.careGoal.careGoalID
        )
        let sinks: [String: any SettleCareGoalWorkflowIDTarget] = [
            "medication-validation": SettleCareGoalWorkflowIDMedicationValidation(client: Acme_Prescriptions_V1_MedicationValidationService.Client(wrapping: mesh)),
            "visit-note-validation": SettleCareGoalWorkflowIDVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)),
        ]
        try await route("visit-note-validation", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: SettleCareGoalWorkflowIDRecord, _ sinks: [String: any SettleCareGoalWorkflowIDTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.write(rec)
    }
}
