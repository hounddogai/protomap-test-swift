import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleCareGoalID keeps of each SuspendCareGoal response.
struct SettleCareGoalIDRecord {
    var careGoalID: String
    var status: String
}

/// Where SettleCareGoalID hands each record.
protocol SettleCareGoalIDWriter {
    func apply(_ rec: SettleCareGoalIDRecord) async throws
}

/// Passes records to acme.telehealth.v1.VisitNoteCalculationService.
struct SettleCareGoalIDVisitNoteCalculation: SettleCareGoalIDWriter {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func apply(_ rec: SettleCareGoalIDRecord) async throws {
        _ = try await client.getVisitNoteRates(.with {
            $0.visitNoteID = rec.status
        })
    }
}

/// Sends records to acme.prescriptions.v1.MedicationQueryService.
struct SettleCareGoalIDMedicationQuery: SettleCareGoalIDWriter {
    let client: Acme_Prescriptions_V1_MedicationQueryService.Client<MeshTransport>

    func apply(_ rec: SettleCareGoalIDRecord) async throws {
        _ = try await client.findMedications(.with {
            $0.filter.region = rec.status
            $0.filter.query = rec.careGoalID
        })
    }
}

/// Reads acme.careplans.v1.CareGoalLifecycleService/SuspendCareGoal and hands what it keeps to the sink of its kind.
enum SettleCareGoalID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)
        let got = try await source.suspendCareGoal(.with { $0.careGoalID = "nightly-settle-care-goal-id" })
        let entry = SettleCareGoalIDRecord(
            careGoalID: got.careGoal.careGoalID,
            status: got.result.status
        )
        let sinks: [any SettleCareGoalIDWriter] = [
            SettleCareGoalIDVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)),
            SettleCareGoalIDMedicationQuery(client: Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.apply(entry)
        }
    }
}
