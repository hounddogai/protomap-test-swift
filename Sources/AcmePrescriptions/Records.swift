import AcmeContracts
import AcmePlatform
import Foundation
import SwiftProtobuf

/// The stored representation of a medication.
struct MedicationRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Prescriptions_V1_Medication, tenant: String) throws {
        self.identifier = message.medicationID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "medication", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Prescriptions_V1_Medication {
        try Acme_Prescriptions_V1_Medication(serializedBytes: payload)
    }
}

/// The stored representation of a prescription.
struct PrescriptionRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Prescriptions_V1_Prescription, tenant: String) throws {
        self.identifier = message.prescriptionID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "prescription", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Prescriptions_V1_Prescription {
        try Acme_Prescriptions_V1_Prescription(serializedBytes: payload)
    }
}

/// The stored representation of a refill.
struct RefillRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Prescriptions_V1_Refill, tenant: String) throws {
        self.identifier = message.refillID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "refill", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Prescriptions_V1_Refill {
        try Acme_Prescriptions_V1_Refill(serializedBytes: payload)
    }
}
