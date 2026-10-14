import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorPatientHomeSubscriptionsID keeps of each ListPatientHomeSubscriptions response.
struct MirrorPatientHomeSubscriptionsIDRecord {
    var correlationID: String
    var message: String
    var nextPageToken: String
    var status: String
}

/// Where MirrorPatientHomeSubscriptionsID hands each record.
protocol MirrorPatientHomeSubscriptionsIDDestination {
    func send(_ rec: MirrorPatientHomeSubscriptionsIDRecord) async throws
}

/// Writes records to acme.shows.v1.ShowQueryService.
struct MirrorPatientHomeSubscriptionsIDShowQuery: MirrorPatientHomeSubscriptionsIDDestination {
    let client: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>

    func send(_ rec: MirrorPatientHomeSubscriptionsIDRecord) async throws {
        _ = try await client.summarizeShows(.with {
            $0.reason = rec.message
        })
    }
}

/// Sends records to acme.audit.v1.AuditEventQueryService.
struct MirrorPatientHomeSubscriptionsIDAuditEventQuery: MirrorPatientHomeSubscriptionsIDDestination {
    let client: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>

    func send(_ rec: MirrorPatientHomeSubscriptionsIDRecord) async throws {
        _ = try await client.lookupAuditEvent(.with {
            $0.auditEventID = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct MirrorPatientHomeSubscriptionsIDLogOnly: MirrorPatientHomeSubscriptionsIDDestination {
    let logger = Logger(label: "acme.mirror-patient-home-subscriptions-id")

    func send(_ rec: MirrorPatientHomeSubscriptionsIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.patientapp.v1.PatientHomeNotificationService/ListPatientHomeSubscriptions and hands what it keeps to the sink of its kind.
enum MirrorPatientHomeSubscriptionsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patientapp_V1_PatientHomeNotificationService.Client(wrapping: mesh)
        let got = try await reader.listPatientHomeSubscriptions(.with { $0.orderBy = "nightly-mirror-patient-home-subscriptions-id" })
        let rec = MirrorPatientHomeSubscriptionsIDRecord(
            correlationID: Kit.Text.normalize(got.result.correlationID),
            message: Kit.Text.normalize(got.result.message),
            nextPageToken: got.pageInfo.nextPageToken,
            status: got.result.status
        )
        try await deliver("show-query", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: MirrorPatientHomeSubscriptionsIDRecord, _ mesh: MeshClient) async throws {
        var sink: any MirrorPatientHomeSubscriptionsIDDestination = MirrorPatientHomeSubscriptionsIDLogOnly()
        switch kind {
        case "show-query":
            sink = MirrorPatientHomeSubscriptionsIDShowQuery(client: Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh))
        case "audit-event-query":
            sink = MirrorPatientHomeSubscriptionsIDAuditEventQuery(client: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
