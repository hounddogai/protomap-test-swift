import AcmeContracts
import AcmePlatform
import Foundation
import SwiftProtobuf

/// The stored representation of a care inbox.
struct CareInboxRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Patientapp_V1_CareInbox, tenant: String) throws {
        self.identifier = message.careInboxID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "care_inbox", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Patientapp_V1_CareInbox {
        try Acme_Patientapp_V1_CareInbox(serializedBytes: payload)
    }
}

/// The stored representation of a patient home.
struct PatientHomeRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Patientapp_V1_PatientHome, tenant: String) throws {
        self.identifier = message.patientHomeID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "patient_home", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Patientapp_V1_PatientHome {
        try Acme_Patientapp_V1_PatientHome(serializedBytes: payload)
    }
}
