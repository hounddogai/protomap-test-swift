import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncMedicationMessage keeps of each RecallMedication response.
struct SyncMedicationMessageRecord {
    var message: String
    var referenceID: String
    var code: String
}

/// Where SyncMedicationMessage hands each record.
protocol SyncMedicationMessageWriter {
    func deliver(_ rec: SyncMedicationMessageRecord) async throws
}

/// Sends records to acme.careplans.v1.CarePlanCalculationService.
struct SyncMedicationMessageCarePlanCalculation: SyncMedicationMessageWriter {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicationMessageRecord) async throws {
        let request = Acme_Careplans_V1_SimulateCarePlanRequest.with {
            $0.carePlan.number = rec.message
            $0.carePlan.carePlanID = rec.referenceID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulateCarePlan(request)
        }
    }
}

/// Writes records to acme.shows.v1.ShowService.
struct SyncMedicationMessageShow: SyncMedicationMessageWriter {
    let client: Acme_Shows_V1_ShowService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicationMessageRecord) async throws {
        _ = try await client.getShow(.with {
            $0.showID = rec.referenceID
        })
    }
}

/// Hands records to acme.telehealth.v1.TriageCalculationService.
struct SyncMedicationMessageTriageCalculation: SyncMedicationMessageWriter {
    let client: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>

    func deliver(_ rec: SyncMedicationMessageRecord) async throws {
        let request = Acme_Telehealth_V1_GetTriageRatesRequest.with {
            $0.triageID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getTriageRates(request)
        }
    }
}

/// Reads acme.prescriptions.v1.MedicationApprovalService/RecallMedication and hands what it keeps to the sink of its kind.
enum SyncMedicationMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh)
        let found = try await origin.recallMedication(.with { $0.medicationID = "main-sync-medication-message" })
        let row = SyncMedicationMessageRecord(
            message: found.outcome.message,
            referenceID: found.outcome.referenceID,
            code: Kit.Text.normalize(found.medication.code)
        )
        let sinks: [any SyncMedicationMessageWriter] = [
            SyncMedicationMessageCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)),
            SyncMedicationMessageShow(client: Acme_Shows_V1_ShowService.Client(wrapping: mesh)),
            SyncMedicationMessageTriageCalculation(client: Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.deliver(row)
        }
    }
}
