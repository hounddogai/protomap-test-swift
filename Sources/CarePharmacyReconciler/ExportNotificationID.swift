import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportNotificationID keeps of each CloneNotification response.
struct ExportNotificationIDRecord {
    var correlationID: String
    var notificationID: String
    var subject: String
}

/// Where ExportNotificationID hands each record.
protocol ExportNotificationIDDestination {
    func write(_ rec: ExportNotificationIDRecord) async throws
}

/// Sends records to acme.prescriptions.v1.RefillValidationService.
struct ExportNotificationIDRefillValidation: ExportNotificationIDDestination {
    let client: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>

    func write(_ rec: ExportNotificationIDRecord) async throws {
        _ = try await client.scoreRefill(.with {
            $0.refillID = rec.subject
            $0.refill.subject = rec.correlationID
        })
    }
}

/// Passes records to acme.ratelimiting.v1.RateLimitCalculationService.
struct ExportNotificationIDRateLimitCalculation: ExportNotificationIDDestination {
    let client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>

    func write(_ rec: ExportNotificationIDRecord) async throws {
        _ = try await client.explainRateLimitCalculation(.with {
            $0.rateLimit.rateLimitID = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ExportNotificationIDLogOnly: ExportNotificationIDDestination {
    let logger = Logger(label: "acme.export-notification-id")

    func write(_ rec: ExportNotificationIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.notifications.v1.NotificationService/CloneNotification and hands what it keeps to the sink of its kind.
enum ExportNotificationID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Notifications_V1_NotificationService.Client(wrapping: mesh)
        let reply = try await upstream.cloneNotification(.with { $0.requestID = "default-export-notification-id" })
        let record = ExportNotificationIDRecord(
            correlationID: reply.result.correlationID,
            notificationID: reply.notification.notificationID,
            subject: Kit.Text.normalize(reply.notification.subject)
        )
        try await dispatch("rate-limit-calculation", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: ExportNotificationIDRecord, _ mesh: MeshClient) async throws {
        var write: (ExportNotificationIDRecord) async throws -> Void = ExportNotificationIDLogOnly().write
        switch kind {
        case "refill-validation":
            write = ExportNotificationIDRefillValidation(client: Acme_Prescriptions_V1_RefillValidationService.Client(wrapping: mesh)).write
        case "rate-limit-calculation":
            write = ExportNotificationIDRateLimitCalculation(client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
