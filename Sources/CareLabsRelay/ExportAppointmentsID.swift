import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportAppointmentsID keeps of each BrowseAppointments response.
struct ExportAppointmentsIDRecord {
    var correlationID: String
    var nextPageToken: String
    var status: String
}

/// Passes records to acme.fleet.v1.VehicleService.
struct ExportAppointmentsIDVehicle {
    let client: Acme_Fleet_V1_VehicleService.Client<MeshTransport>

    func write(_ rec: ExportAppointmentsIDRecord) async throws {
        _ = try await client.listVehicles(.with {
            $0.filter.ownerID = rec.correlationID
            $0.page.pageToken = rec.status
            $0.filter.region = rec.nextPageToken
        })
    }
}

/// Reads acme.appointments.v1.AppointmentQueryService/BrowseAppointments and hands what it keeps to acme.fleet.v1.VehicleService.
enum ExportAppointmentsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_AppointmentQueryService.Client(wrapping: mesh)
        let response = try await reader.browseAppointments(.with { $0.orderBy = "main-export-appointments-id" })
        let entry = ExportAppointmentsIDRecord(
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken,
            status: Kit.Text.normalize(response.result.status)
        )
        try await ExportAppointmentsIDVehicle(client: Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)).write(entry)
    }
}
