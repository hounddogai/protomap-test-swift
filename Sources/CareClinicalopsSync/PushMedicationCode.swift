import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushMedicationCode keeps of each PeekMedication response.
struct PushMedicationCodeRecord {
    var code: String
    var correlationID: String
    var medicationID: String
}

/// Where PushMedicationCode hands each record.
protocol PushMedicationCodeWriter {
    func apply(_ rec: PushMedicationCodeRecord) async throws
}

/// Passes records to acme.patientapp.v1.CareInboxIntegrationService.
struct PushMedicationCodeCareInboxIntegration: PushMedicationCodeWriter {
    let client: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>

    func apply(_ rec: PushMedicationCodeRecord) async throws {
        _ = try await client.listCareInboxSources(.with {
            $0.filter.query = rec.code
            $0.filter.region = rec.correlationID
        })
    }
}

/// Hands records to acme.concessions.v1.ConcessionStandCalculationService.
struct PushMedicationCodeConcessionStandCalculation: PushMedicationCodeWriter {
    let client: Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>

    func apply(_ rec: PushMedicationCodeRecord) async throws {
        let request = Acme_Concessions_V1_RecalculateConcessionStandsRequest.with {
            $0.concessionStandID = rec.code
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.recalculateConcessionStands(request)
        }
    }
}

/// Reads acme.prescriptions.v1.MedicationQueryService/PeekMedication and hands what it keeps to the sink of its kind.
enum PushMedicationCode {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)
        let got = try await reader.peekMedication(.with { $0.medicationID = "nightly-push-medication-code" })
        let row = PushMedicationCodeRecord(
            code: got.medication.code,
            correlationID: Kit.Text.normalize(got.result.correlationID),
            medicationID: Kit.Text.normalize(got.medication.medicationID)
        )
        let sinks: [any PushMedicationCodeWriter] = [
            PushMedicationCodeCareInboxIntegration(client: Acme_Patientapp_V1_CareInboxIntegrationService.Client(wrapping: mesh)),
            PushMedicationCodeConcessionStandCalculation(client: Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].apply(row)
    }
}
