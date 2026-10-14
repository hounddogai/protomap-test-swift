import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayDocumentsStatus keeps of each CountDocuments response.
struct ReplayDocumentsStatusRecord {
    var status: String
    var correlationID: String
}

/// Hands records to acme.prescriptions.v1.MedicationCalculationService.
struct ReplayDocumentsStatusMedicationCalculation {
    let client: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>

    func deliver(_ rec: ReplayDocumentsStatusRecord) async throws {
        _ = try await client.explainMedicationCalculation(.with {
            $0.medicationID = rec.status
            $0.reason = rec.correlationID
        })
    }
}

/// Reads acme.documents.v1.DocumentQueryService/CountDocuments and hands what it keeps to acme.prescriptions.v1.MedicationCalculationService.
enum ReplayDocumentsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)
        let got = try await upstream.countDocuments(.with { $0.orderBy = "primary-replay-documents-status" })
        let entry = ReplayDocumentsStatusRecord(
            status: got.result.status,
            correlationID: Kit.Text.normalize(got.result.correlationID)
        )
        try await ReplayDocumentsStatusMedicationCalculation(client: Acme_Prescriptions_V1_MedicationCalculationService.Client(wrapping: mesh)).deliver(entry)
    }
}
