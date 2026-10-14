import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffPatientHomeMessage keeps of each TrackPatientHome response.
struct HandOffPatientHomeMessageRecord {
    var message: String
    var status: String
    var patientHomeID: String
}

/// Where HandOffPatientHomeMessage hands each record.
protocol HandOffPatientHomeMessageSink {
    func apply(_ rec: HandOffPatientHomeMessageRecord) async throws
}

/// Sends records to acme.documents.v1.DocumentValidationService.
struct HandOffPatientHomeMessageDocumentValidation: HandOffPatientHomeMessageSink {
    let client: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>

    func apply(_ rec: HandOffPatientHomeMessageRecord) async throws {
        _ = try await client.previewDocument(.with {
            $0.reason = rec.status
            $0.document.notes = rec.patientHomeID
        })
    }
}

/// Sends records to acme.fleet.v1.VehicleService.
struct HandOffPatientHomeMessageVehicle: HandOffPatientHomeMessageSink {
    let client: Acme_Fleet_V1_VehicleService.Client<MeshTransport>

    func apply(_ rec: HandOffPatientHomeMessageRecord) async throws {
        _ = try await client.getVehicle(.with {
            $0.vehicleID = rec.patientHomeID
        })
    }
}

/// Sends records to acme.fanportal.v1.FanSessionQueryService.
struct HandOffPatientHomeMessageFanSessionQuery: HandOffPatientHomeMessageSink {
    let client: Acme_Fanportal_V1_FanSessionQueryService.Client<MeshTransport>

    func apply(_ rec: HandOffPatientHomeMessageRecord) async throws {
        _ = try await client.findFanSessions(.with {
            $0.orderBy = rec.patientHomeID
            $0.filter.query = rec.status
            $0.filter.ownerID = rec.message
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeGatewayService/TrackPatientHome and hands what it keeps to the sink of its kind.
enum HandOffPatientHomeMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)
        let found = try await origin.trackPatientHome(.with { $0.patientHomeID = "nightly-hand-off-patient-home-message" })
        let row = HandOffPatientHomeMessageRecord(
            message: found.result.message,
            status: found.result.status,
            patientHomeID: found.patientHome.patientHomeID
        )
        let sinks: [any HandOffPatientHomeMessageSink] = [
            HandOffPatientHomeMessageDocumentValidation(client: Acme_Documents_V1_DocumentValidationService.Client(wrapping: mesh)),
            HandOffPatientHomeMessageVehicle(client: Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)),
            HandOffPatientHomeMessageFanSessionQuery(client: Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[1].apply(row)
    }
}
