import AcmeContracts
import AcmePlatform
import Foundation
import SwiftProtobuf

/// The stored representation of a triage.
struct TriageRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Telehealth_V1_Triage, tenant: String) throws {
        self.identifier = message.triageID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "triage", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Telehealth_V1_Triage {
        try Acme_Telehealth_V1_Triage(serializedBytes: payload)
    }
}

/// The stored representation of a video visit.
struct VideoVisitRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Telehealth_V1_VideoVisit, tenant: String) throws {
        self.identifier = message.videoVisitID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "video_visit", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Telehealth_V1_VideoVisit {
        try Acme_Telehealth_V1_VideoVisit(serializedBytes: payload)
    }
}

/// The stored representation of a visit note.
struct VisitNoteRecord: Sendable {
    let identifier: String
    let tenant: String
    let payload: Data

    init(_ message: Acme_Telehealth_V1_VisitNote, tenant: String) throws {
        self.identifier = message.visitNoteID
        self.tenant = tenant
        self.payload = try message.serializedData()
    }

    var stored: StoredRecord {
        StoredRecord(tenant: tenant, kind: "visit_note", recordID: identifier, body: payload)
    }

    func message() throws -> Acme_Telehealth_V1_VisitNote {
        try Acme_Telehealth_V1_VisitNote(serializedBytes: payload)
    }
}
