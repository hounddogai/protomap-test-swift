import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillMedicalRecordID keeps of each LookupMedicalRecord response.
struct BackfillMedicalRecordIDRecord {
    var medicalRecordID: String
    var correlationID: String
    var number: String
    var notes: String
}

/// Where BackfillMedicalRecordID hands each record.
protocol BackfillMedicalRecordIDTarget {
    func send(_ rec: BackfillMedicalRecordIDRecord) async throws
}

/// Writes records to acme.shipping.v1.ShipmentService.
struct BackfillMedicalRecordIDShipment: BackfillMedicalRecordIDTarget {
    let client: Acme_Shipping_V1_ShipmentService.Client<MeshTransport>

    func send(_ rec: BackfillMedicalRecordIDRecord) async throws {
        _ = try await client.updateShipment(.with {
            $0.shipment.shipmentID = rec.number
            $0.shipment.notes = rec.notes
            $0.shipment.number = rec.correlationID
        })
    }
}

/// Writes records to acme.appointments.v1.AppointmentQueryService.
struct BackfillMedicalRecordIDAppointmentQuery: BackfillMedicalRecordIDTarget {
    let client: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>

    func send(_ rec: BackfillMedicalRecordIDRecord) async throws {
        _ = try await client.lookupAppointment(.with {
            $0.appointmentID = rec.number
        })
    }
}

/// Hands records to acme.authorization.v1.AccessPolicyService.
struct BackfillMedicalRecordIDAccessPolicy: BackfillMedicalRecordIDTarget {
    let client: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>

    func send(_ rec: BackfillMedicalRecordIDRecord) async throws {
        _ = try await client.updateAccessPolicy(.with {
            $0.accessPolicy.name = rec.correlationID
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordQueryService/LookupMedicalRecord and hands what it keeps to the sink of its kind.
enum BackfillMedicalRecordID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh)
        let reply = try await upstream.lookupMedicalRecord(.with { $0.medicalRecordID = "default-backfill-medical-record-id" })
        let record = BackfillMedicalRecordIDRecord(
            medicalRecordID: reply.medicalRecord.medicalRecordID,
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            number: reply.medicalRecord.number,
            notes: reply.medicalRecord.notes
        )
        let sinks: [any BackfillMedicalRecordIDTarget] = [
            BackfillMedicalRecordIDShipment(client: Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh)),
            BackfillMedicalRecordIDAppointmentQuery(client: Acme_Appointments_V1_AppointmentQueryService.Client(wrapping: mesh)),
            BackfillMedicalRecordIDAccessPolicy(client: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)),
        ]
        try await sinks[2].send(record)
    }
}
