import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryCareInboxesUri keeps of each SummarizeCareInboxes response.
struct CarryCareInboxesUriRecord {
    var downloadUri: String
    var correlationID: String
    var reportID: String
}

/// Where CarryCareInboxesUri hands each record.
protocol CarryCareInboxesUriTarget {
    func apply(_ rec: CarryCareInboxesUriRecord) async throws
}

/// Passes records to acme.patientapp.v1.CareInboxNotificationService.
struct CarryCareInboxesUriCareInboxNotification: CarryCareInboxesUriTarget {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func apply(_ rec: CarryCareInboxesUriRecord) async throws {
        let request = Acme_Patientapp_V1_SubscribeCareInboxUpdatesRequest.with {
            $0.careInboxID = rec.downloadUri
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.subscribeCareInboxUpdates(request)
        }
    }
}

/// Hands records to acme.telehealth.v1.TriageValidationService.
struct CarryCareInboxesUriTriageValidation: CarryCareInboxesUriTarget {
    let client: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>

    func apply(_ rec: CarryCareInboxesUriRecord) async throws {
        let request = Acme_Telehealth_V1_ScoreTriageRequest.with {
            $0.details.currencyCode = rec.downloadUri
            $0.triageID = rec.reportID
            $0.triage.subject = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreTriage(request)
        }
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteWorkflowService.
struct CarryCareInboxesUriVisitNoteWorkflow: CarryCareInboxesUriTarget {
    let client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>

    func apply(_ rec: CarryCareInboxesUriRecord) async throws {
        _ = try await client.signalVisitNoteWorkflow(.with {
            $0.visitNote.number = rec.reportID
            $0.visitNote.visitNoteID = rec.downloadUri
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CarryCareInboxesUriLogOnly: CarryCareInboxesUriTarget {
    let logger = Logger(label: "acme.carry-care-inboxes-uri")

    func apply(_ rec: CarryCareInboxesUriRecord) async throws {
        logger.info("No sink for record", metadata: ["downloadUri": .string(rec.downloadUri)])
    }
}

/// Reads acme.patientapp.v1.CareInboxQueryService/SummarizeCareInboxes and hands what it keeps to the sink of its kind.
enum CarryCareInboxesUri {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: mesh)
        let reply = try await origin.summarizeCareInboxes(.with { $0.careInboxID = "current-carry-care-inboxes-uri" })
        let entry = CarryCareInboxesUriRecord(
            downloadUri: reply.downloadUri,
            correlationID: reply.result.correlationID,
            reportID: reply.reportID
        )
        try await deliver("care-inbox-notification", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CarryCareInboxesUriRecord, _ mesh: MeshClient) async throws {
        var sink: any CarryCareInboxesUriTarget = CarryCareInboxesUriLogOnly()
        switch kind {
        case "care-inbox-notification":
            sink = CarryCareInboxesUriCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh))
        case "triage-validation":
            sink = CarryCareInboxesUriTriageValidation(client: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: mesh))
        case "visit-note-workflow":
            sink = CarryCareInboxesUriVisitNoteWorkflow(client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
