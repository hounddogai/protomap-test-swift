import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushVehicleStatus keeps of each GetVehicle response.
struct PushVehicleStatusRecord {
    var status: String
    var code: String
}

/// Hands records to acme.appointments.v1.ClinicSlotValidationService.
struct PushVehicleStatusClinicSlotValidation {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func forward(_ rec: PushVehicleStatusRecord) async throws {
        _ = try await client.explainClinicSlotDecision(.with {
            $0.clinicSlotID = rec.status
            $0.reason = rec.code
        })
    }
}

/// Reads acme.fleet.v1.VehicleService/GetVehicle and hands what it keeps to acme.appointments.v1.ClinicSlotValidationService.
enum PushVehicleStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)
        let found = try await reader.getVehicle(.with { $0.vehicleID = "nightly-push-vehicle-status" })
        let rec = PushVehicleStatusRecord(
            status: found.result.status,
            code: found.vehicle.code
        )
        try await PushVehicleStatusClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)).forward(rec)
    }
}
