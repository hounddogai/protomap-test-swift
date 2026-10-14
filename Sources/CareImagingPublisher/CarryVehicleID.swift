import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryVehicleID keeps of each CloneVehicle response.
struct CarryVehicleIDRecord {
    var correlationID: String
    var name: String
    var message: String
}

/// Where CarryVehicleID hands each record.
protocol CarryVehicleIDWriter {
    func forward(_ rec: CarryVehicleIDRecord) async throws
}

/// Hands records to acme.careplans.v1.VitalReportingService.
struct CarryVehicleIDVitalReporting: CarryVehicleIDWriter {
    let client: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>

    func forward(_ rec: CarryVehicleIDRecord) async throws {
        _ = try await client.deleteVitalReport(.with {
            $0.etag = rec.correlationID
        })
    }
}

/// Writes records to acme.patients.v1.MedicalRecordApprovalService.
struct CarryVehicleIDMedicalRecordApproval: CarryVehicleIDWriter {
    let client: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>

    func forward(_ rec: CarryVehicleIDRecord) async throws {
        _ = try await client.getMedicalRecordApprovalStatus(.with {
            $0.medicalRecordID = rec.message
        })
    }
}

/// Reads acme.fleet.v1.VehicleService/CloneVehicle and hands what it keeps to the sink of its kind.
enum CarryVehicleID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)
        let got = try await origin.cloneVehicle(.with { $0.requestID = "primary-carry-vehicle-id" })
        let record = CarryVehicleIDRecord(
            correlationID: got.result.correlationID,
            name: got.vehicle.name,
            message: Kit.Text.normalize(got.result.message)
        )
        let sinks: [String: any CarryVehicleIDWriter] = [
            "vital-reporting": CarryVehicleIDVitalReporting(client: Acme_Careplans_V1_VitalReportingService.Client(wrapping: mesh)),
            "medical-record-approval": CarryVehicleIDMedicalRecordApproval(client: Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)),
        ]
        try await route("vital-reporting", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: CarryVehicleIDRecord, _ sinks: [String: any CarryVehicleIDWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.forward(rec)
    }
}
