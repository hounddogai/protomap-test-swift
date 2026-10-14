import AcmeContracts
import AcmePlatform
import Foundation
import SwiftProtobuf

/// The stored representation of a appointment.
struct AppointmentRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Appointments_V1_Appointment, tenant: String) throws {
        self.identifier = message.appointmentID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "appointment", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Appointments_V1_Appointment {
        try Acme_Appointments_V1_Appointment(serializedBytes: payload)
    }
}

/// The stored representation of a clinic slot.
struct ClinicSlotRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Appointments_V1_ClinicSlot, tenant: String) throws {
        self.identifier = message.clinicSlotID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "clinic_slot", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Appointments_V1_ClinicSlot {
        try Acme_Appointments_V1_ClinicSlot(serializedBytes: payload)
    }
}

/// The stored representation of a provider.
struct ProviderRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Appointments_V1_Provider, tenant: String) throws {
        self.identifier = message.providerID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "provider", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Appointments_V1_Provider {
        try Acme_Appointments_V1_Provider(serializedBytes: payload)
    }
}
