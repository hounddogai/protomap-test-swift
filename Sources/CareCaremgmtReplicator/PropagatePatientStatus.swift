import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagatePatientStatus keeps of each SubmitPatient response.
struct PropagatePatientStatusRecord {
    var status: String
    var correlationID: String
    var resultStatus: String
}

/// Where PropagatePatientStatus hands each record.
protocol PropagatePatientStatusDestination {
    func write(_ rec: PropagatePatientStatusRecord) async throws
}

/// Writes records to acme.treasury.v1.CashPositionService.
struct PropagatePatientStatusCashPosition: PropagatePatientStatusDestination {
    let client: Acme_Treasury_V1_CashPositionService.Client<MeshTransport>

    func write(_ rec: PropagatePatientStatusRecord) async throws {
        _ = try await client.getCashPosition(.with {
            $0.cashPositionID = rec.status
        })
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteCalculationService.
struct PropagatePatientStatusVisitNoteCalculation: PropagatePatientStatusDestination {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func write(_ rec: PropagatePatientStatusRecord) async throws {
        _ = try await client.calculateVisitNote(.with {
            $0.visitNote.number = rec.correlationID
        })
    }
}

/// Passes records to acme.careplans.v1.CareGoalWorkflowService.
struct PropagatePatientStatusCareGoalWorkflow: PropagatePatientStatusDestination {
    let client: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>

    func write(_ rec: PropagatePatientStatusRecord) async throws {
        _ = try await client.advanceCareGoalWorkflow(.with {
            $0.careGoal.subject = rec.correlationID
            $0.details.step = rec.status
        })
    }
}

/// Reads acme.patients.v1.PatientApprovalService/SubmitPatient and hands what it keeps to the sink of its kind.
enum PropagatePatientStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)
        let found = try await source.submitPatient(.with { $0.patientID = "default-propagate-patient-status" })
        let rec = PropagatePatientStatusRecord(
            status: Kit.Text.normalize(found.outcome.status),
            correlationID: found.result.correlationID,
            resultStatus: Kit.Text.normalize(found.result.status)
        )
        try await act("visit-note-calculation", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: PropagatePatientStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "cash-position": { try await PropagatePatientStatusCashPosition(client: Acme_Treasury_V1_CashPositionService.Client(wrapping: mesh)).write(rec) },
            "visit-note-calculation": { try await PropagatePatientStatusVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)).write(rec) },
            "care-goal-workflow": { try await PropagatePatientStatusCareGoalWorkflow(client: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
