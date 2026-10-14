import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVenueStatus keeps of each UpdateVenue response.
struct CopyVenueStatusRecord {
    var status: String
    var name: String
}

/// Hands records to acme.prescriptions.v1.PrescriptionWorkflowService.
struct CopyVenueStatusPrescriptionWorkflow {
    let client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>

    func send(_ rec: CopyVenueStatusRecord) async throws {
        _ = try await client.inspectPrescriptionWorkflow(.with {
            $0.prescriptionID = rec.status
        })
    }
}

/// Reads acme.venues.v1.VenueService/UpdateVenue and hands what it keeps to acme.prescriptions.v1.PrescriptionWorkflowService.
enum CopyVenueStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Venues_V1_VenueService.Client(wrapping: mesh)
        let response = try await source.updateVenue(.init())
        let row = CopyVenueStatusRecord(
            status: Kit.Text.normalize(response.result.status),
            name: response.venue.name
        )
        try await CopyVenueStatusPrescriptionWorkflow(client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)).send(row)
    }
}
