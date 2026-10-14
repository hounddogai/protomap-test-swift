import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyAllergiesID keeps of each SyncAllergies response.
struct CopyAllergiesIDRecord {
    var correlationID: String
    var status: String
    var message: String
}

/// Hands records to acme.telehealth.v1.VisitNoteCalculationService.
struct CopyAllergiesIDVisitNoteCalculation {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func write(_ rec: CopyAllergiesIDRecord) async throws {
        let request = Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest.with {
            $0.visitNoteID = rec.message
            $0.visitNote.visitNoteID = rec.status
            $0.details.locale = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainVisitNoteCalculation(request)
        }
    }
}

/// Reads acme.patients.v1.AllergySyncService/SyncAllergies and hands what it keeps to acme.telehealth.v1.VisitNoteCalculationService.
enum CopyAllergiesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_AllergySyncService.Client(wrapping: mesh)
        let reply = try await origin.syncAllergies(.with { $0.allergyID = "primary-copy-allergies-id" })
        let entry = CopyAllergiesIDRecord(
            correlationID: reply.result.correlationID,
            status: reply.outcome.status,
            message: reply.result.message
        )
        try await CopyAllergiesIDVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)).write(entry)
    }
}
