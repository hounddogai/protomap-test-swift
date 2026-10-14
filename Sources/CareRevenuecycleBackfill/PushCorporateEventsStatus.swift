import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushCorporateEventsStatus keeps of each CountCorporateEvents response.
struct PushCorporateEventsStatusRecord {
    var status: String
    var correlationID: String
    var message: String
}

/// Where PushCorporateEventsStatus hands each record.
protocol PushCorporateEventsStatusSink {
    func forward(_ rec: PushCorporateEventsStatusRecord) async throws
}

/// Passes records to acme.corporateevents.v1.CorporateEventQueryService.
struct PushCorporateEventsStatusCorporateEventQuery: PushCorporateEventsStatusSink {
    let client: Acme_Corporateevents_V1_CorporateEventQueryService.Client<MeshTransport>

    func forward(_ rec: PushCorporateEventsStatusRecord) async throws {
        _ = try await client.lookupCorporateEvent(.with {
            $0.corporateEventID = rec.status
        })
    }
}

/// Writes records to acme.audit.v1.AuditEventQueryService.
struct PushCorporateEventsStatusAuditEventQuery: PushCorporateEventsStatusSink {
    let client: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>

    func forward(_ rec: PushCorporateEventsStatusRecord) async throws {
        let request = Acme_Audit_V1_CountAuditEventsRequest.with {
            $0.filter.query = rec.message
            $0.orderBy = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countAuditEvents(request)
        }
    }
}

/// Writes records to acme.certificates.v1.CertificateService.
struct PushCorporateEventsStatusCertificate: PushCorporateEventsStatusSink {
    let client: Acme_Certificates_V1_CertificateService.Client<MeshTransport>

    func forward(_ rec: PushCorporateEventsStatusRecord) async throws {
        let request = Acme_Certificates_V1_UpdateCertificateRequest.with {
            $0.certificate.notes = rec.status
            $0.certificate.certificateID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateCertificate(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PushCorporateEventsStatusLogOnly: PushCorporateEventsStatusSink {
    let logger = Logger(label: "acme.push-corporate-events-status")

    func forward(_ rec: PushCorporateEventsStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.corporateevents.v1.CorporateEventQueryService/CountCorporateEvents and hands what it keeps to the sink of its kind.
enum PushCorporateEventsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Corporateevents_V1_CorporateEventQueryService.Client(wrapping: mesh)
        let response = try await reader.countCorporateEvents(.with { $0.orderBy = "default-push-corporate-events-status" })
        let rec = PushCorporateEventsStatusRecord(
            status: response.result.status,
            correlationID: response.result.correlationID,
            message: response.result.message
        )
        try await dispatch("certificate", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PushCorporateEventsStatusRecord, _ mesh: MeshClient) async throws {
        var write: (PushCorporateEventsStatusRecord) async throws -> Void = PushCorporateEventsStatusLogOnly().forward
        switch kind {
        case "corporate-event-query":
            write = PushCorporateEventsStatusCorporateEventQuery(client: Acme_Corporateevents_V1_CorporateEventQueryService.Client(wrapping: mesh)).forward
        case "audit-event-query":
            write = PushCorporateEventsStatusAuditEventQuery(client: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: mesh)).forward
        case "certificate":
            write = PushCorporateEventsStatusCertificate(client: Acme_Certificates_V1_CertificateService.Client(wrapping: mesh)).forward
        default:
            break
        }
        try await write(rec)
    }
}
