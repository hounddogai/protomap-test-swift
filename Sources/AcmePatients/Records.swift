import AcmeContracts
import AcmePlatform
import Foundation
import SwiftProtobuf

/// The stored representation of a allergy.
struct AllergyRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Patients_V1_Allergy, tenant: String) throws {
        self.identifier = message.allergyID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "allergy", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Patients_V1_Allergy {
        try Acme_Patients_V1_Allergy(serializedBytes: payload)
    }
}

/// The stored representation of a medical record.
struct MedicalRecordRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Patients_V1_MedicalRecord, tenant: String) throws {
        self.identifier = message.medicalRecordID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "medical_record", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Patients_V1_MedicalRecord {
        try Acme_Patients_V1_MedicalRecord(serializedBytes: payload)
    }
}

/// The stored representation of a patient.
struct PatientRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Patients_V1_Patient, tenant: String) throws {
        self.identifier = message.patientID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "patient", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Patients_V1_Patient {
        try Acme_Patients_V1_Patient(serializedBytes: payload)
    }
}
