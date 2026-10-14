import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyNotificationSubject keeps of each PreviewNotification response.
struct CopyNotificationSubjectRecord {
    var subject: String
    var message: String
}

/// Where CopyNotificationSubject hands each record.
protocol CopyNotificationSubjectTarget {
    func forward(_ rec: CopyNotificationSubjectRecord) async throws
}

/// Passes records to acme.catalog.v1.ProductQueryService.
struct CopyNotificationSubjectProductQuery: CopyNotificationSubjectTarget {
    let client: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>

    func forward(_ rec: CopyNotificationSubjectRecord) async throws {
        _ = try await client.lookupProduct(.with {
            $0.productID = rec.subject
        })
    }
}

/// Sends records to acme.audit.v1.AuditEventService.
struct CopyNotificationSubjectAuditEvent: CopyNotificationSubjectTarget {
    let client: Acme_Audit_V1_AuditEventService.Client<MeshTransport>

    func forward(_ rec: CopyNotificationSubjectRecord) async throws {
        _ = try await client.createAuditEvent(.with {
            $0.auditEvent.correlationID = rec.message
        })
    }
}

/// Sends records to acme.timekeeping.v1.TimesheetQueryService.
struct CopyNotificationSubjectTimesheetQuery: CopyNotificationSubjectTarget {
    let client: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>

    func forward(_ rec: CopyNotificationSubjectRecord) async throws {
        let request = Acme_Timekeeping_V1_SuggestTimesheetsRequest.with {
            $0.filter.query = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestTimesheets(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct CopyNotificationSubjectLogOnly: CopyNotificationSubjectTarget {
    let logger = Logger(label: "acme.copy-notification-subject")

    func forward(_ rec: CopyNotificationSubjectRecord) async throws {
        logger.info("No sink for record", metadata: ["subject": .string(rec.subject)])
    }
}

/// Reads acme.notifications.v1.NotificationValidationService/PreviewNotification and hands what it keeps to the sink of its kind.
enum CopyNotificationSubject {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh)
        let got = try await reader.previewNotification(.with { $0.reason = "main-copy-notification-subject" })
        let entry = CopyNotificationSubjectRecord(
            subject: got.notification.subject,
            message: got.outcome.message
        )
        try await dispatch("timesheet-query", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: CopyNotificationSubjectRecord, _ mesh: MeshClient) async throws {
        var write: (CopyNotificationSubjectRecord) async throws -> Void = CopyNotificationSubjectLogOnly().forward
        switch kind {
        case "product-query":
            write = CopyNotificationSubjectProductQuery(client: Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)).forward
        case "audit-event":
            write = CopyNotificationSubjectAuditEvent(client: Acme_Audit_V1_AuditEventService.Client(wrapping: mesh)).forward
        case "timesheet-query":
            write = CopyNotificationSubjectTimesheetQuery(client: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: mesh)).forward
        default:
            break
        }
        try await write(rec)
    }
}
