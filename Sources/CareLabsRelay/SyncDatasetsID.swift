import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncDatasetsID keeps of each CountDatasets response.
struct SyncDatasetsIDRecord {
    var correlationID: String
    var message: String
}

/// Where SyncDatasetsID hands each record.
protocol SyncDatasetsIDDestination {
    func apply(_ rec: SyncDatasetsIDRecord) async throws
}

/// Writes records to acme.itsm.v1.IncidentService.
struct SyncDatasetsIDIncident: SyncDatasetsIDDestination {
    let client: Acme_Itsm_V1_IncidentService.Client<MeshTransport>

    func apply(_ rec: SyncDatasetsIDRecord) async throws {
        _ = try await client.searchIncidents(.with {
            $0.filter.region = rec.correlationID
            $0.orderBy = rec.message
        })
    }
}

/// Sends records to acme.documents.v1.DocumentValidationService.
struct SyncDatasetsIDDocumentValidation: SyncDatasetsIDDestination {
    let client: Acme_Documents_V1_DocumentValidationService.Client<MeshTransport>

    func apply(_ rec: SyncDatasetsIDRecord) async throws {
        let request = Acme_Documents_V1_LintDocumentsRequest.with {
            $0.details.locale = rec.message
            $0.document.notes = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintDocuments(request)
        }
    }
}

/// Passes records to acme.recruiting.v1.JobOpeningService.
struct SyncDatasetsIDJobOpening: SyncDatasetsIDDestination {
    let client: Acme_Recruiting_V1_JobOpeningService.Client<MeshTransport>

    func apply(_ rec: SyncDatasetsIDRecord) async throws {
        _ = try await client.deleteJobOpening(.with {
            $0.reason = rec.correlationID
            $0.jobOpeningID = rec.message
        })
    }
}

/// Writes records to acme.notifications.v1.NotificationValidationService.
struct SyncDatasetsIDNotificationValidation: SyncDatasetsIDDestination {
    let client: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>

    func apply(_ rec: SyncDatasetsIDRecord) async throws {
        let request = Acme_Notifications_V1_LintNotificationsRequest.with {
            $0.reason = rec.correlationID
            $0.notification.notificationID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintNotifications(request)
        }
    }
}

/// Reads acme.datasets.v1.DatasetQueryService/CountDatasets and hands what it keeps to the sink of its kind.
enum SyncDatasetsID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Datasets_V1_DatasetQueryService.Client(wrapping: mesh)
        let reply = try await source.countDatasets(.with { $0.orderBy = "default-sync-datasets-id" })
        let rec = SyncDatasetsIDRecord(
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            message: Kit.Text.normalize(reply.result.message)
        )
        let sinks: [String: any SyncDatasetsIDDestination] = [
            "incident": SyncDatasetsIDIncident(client: Acme_Itsm_V1_IncidentService.Client(wrapping: mesh)),
            "document-validation": SyncDatasetsIDDocumentValidation(client: Acme_Documents_V1_DocumentValidationService.Client(wrapping: mesh)),
            "job-opening": SyncDatasetsIDJobOpening(client: Acme_Recruiting_V1_JobOpeningService.Client(wrapping: mesh)),
            "notification-validation": SyncDatasetsIDNotificationValidation(client: Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh)),
        ]
        try await route("job-opening", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: SyncDatasetsIDRecord, _ sinks: [String: any SyncDatasetsIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
