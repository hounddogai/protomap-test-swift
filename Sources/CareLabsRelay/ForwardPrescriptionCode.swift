import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardPrescriptionCode keeps of each SimulatePrescription response.
struct ForwardPrescriptionCodeRecord {
    var currencyCode: String
    var notes: String
    var number: String
    var status: String
}

/// Passes records to acme.telehealth.v1.VideoVisitService.
struct ForwardPrescriptionCodeVideoVisit {
    let client: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>

    func push(_ rec: ForwardPrescriptionCodeRecord) async throws {
        let request = Acme_Telehealth_V1_DeleteVideoVisitRequest.with {
            $0.reason = rec.notes
            $0.videoVisitID = rec.status
            $0.etag = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteVideoVisit(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionCalculationService/SimulatePrescription and hands what it keeps to acme.telehealth.v1.VideoVisitService.
enum ForwardPrescriptionCode {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_PrescriptionCalculationService.Client(wrapping: mesh)
        let got = try await reader.simulatePrescription(.with { $0.reason = "default-forward-prescription-code" })
        let row = ForwardPrescriptionCodeRecord(
            currencyCode: got.breakdown.currencyCode,
            notes: got.prescription.notes,
            number: got.prescription.number,
            status: got.result.status
        )
        try await ForwardPrescriptionCodeVideoVisit(client: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)).push(row)
    }
}
