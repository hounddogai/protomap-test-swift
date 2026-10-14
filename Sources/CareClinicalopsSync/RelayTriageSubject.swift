import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayTriageSubject keeps of each ActivateTriage response.
struct RelayTriageSubjectRecord {
    var subject: String
    var correlationID: String
}

/// Where RelayTriageSubject hands each record.
protocol RelayTriageSubjectWriter {
    func deliver(_ rec: RelayTriageSubjectRecord) async throws
}

/// Hands records to acme.notifications.v1.NotificationValidationService.
struct RelayTriageSubjectNotificationValidation: RelayTriageSubjectWriter {
    let client: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>

    func deliver(_ rec: RelayTriageSubjectRecord) async throws {
        _ = try await client.lintNotifications(.with {
            $0.notification.notificationID = rec.subject
            $0.details.locale = rec.correlationID
        })
    }
}

/// Writes records to acme.telehealth.v1.VideoVisitWorkflowService.
struct RelayTriageSubjectVideoVisitWorkflow: RelayTriageSubjectWriter {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func deliver(_ rec: RelayTriageSubjectRecord) async throws {
        _ = try await client.retryVideoVisitWorkflow(.with {
            $0.videoVisit.videoVisitID = rec.correlationID
        })
    }
}

/// Passes records to acme.sponsorships.v1.SponsorCalculationService.
struct RelayTriageSubjectSponsorCalculation: RelayTriageSubjectWriter {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func deliver(_ rec: RelayTriageSubjectRecord) async throws {
        _ = try await client.recalculateSponsors(.with {
            $0.sponsor.sponsorID = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayTriageSubjectLogOnly: RelayTriageSubjectWriter {
    let logger = Logger(label: "acme.relay-triage-subject")

    func deliver(_ rec: RelayTriageSubjectRecord) async throws {
        logger.info("No sink for record", metadata: ["subject": .string(rec.subject)])
    }
}

/// Reads acme.telehealth.v1.TriageLifecycleService/ActivateTriage and hands what it keeps to the sink of its kind.
enum RelayTriageSubject {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)
        let reply = try await source.activateTriage(.with { $0.reason = "live-relay-triage-subject" })
        let record = RelayTriageSubjectRecord(
            subject: reply.triage.subject,
            correlationID: reply.result.correlationID
        )
        try await deliver("sponsor-calculation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RelayTriageSubjectRecord, _ mesh: MeshClient) async throws {
        var sink: any RelayTriageSubjectWriter = RelayTriageSubjectLogOnly()
        switch kind {
        case "notification-validation":
            sink = RelayTriageSubjectNotificationValidation(client: Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh))
        case "video-visit-workflow":
            sink = RelayTriageSubjectVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh))
        case "sponsor-calculation":
            sink = RelayTriageSubjectSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.deliver(rec)
    }
}
