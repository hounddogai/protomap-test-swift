import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyConcessionStandOptionsCode keeps of each CompareConcessionStandOptions response.
struct CopyConcessionStandOptionsCodeRecord {
    var currencyCode: String
    var message: String
    var concessionStandID: String
}

/// Where CopyConcessionStandOptionsCode hands each record.
protocol CopyConcessionStandOptionsCodeDestination {
    func forward(_ rec: CopyConcessionStandOptionsCodeRecord) async throws
}

/// Sends records to acme.careplans.v1.CareGoalWorkflowService.
struct CopyConcessionStandOptionsCodeCareGoalWorkflow: CopyConcessionStandOptionsCodeDestination {
    let client: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>

    func forward(_ rec: CopyConcessionStandOptionsCodeRecord) async throws {
        _ = try await client.cancelCareGoalWorkflow(.with {
            $0.details.initiatedBy = rec.concessionStandID
        })
    }
}

/// Passes records to acme.notifications.v1.NotificationValidationService.
struct CopyConcessionStandOptionsCodeNotificationValidation: CopyConcessionStandOptionsCodeDestination {
    let client: Acme_Notifications_V1_NotificationValidationService.Client<MeshTransport>

    func forward(_ rec: CopyConcessionStandOptionsCodeRecord) async throws {
        _ = try await client.getNotificationRules(.with {
            $0.notificationID = rec.currencyCode
        })
    }
}

/// Hands records to acme.careplans.v1.CarePlanLifecycleService.
struct CopyConcessionStandOptionsCodeCarePlanLifecycle: CopyConcessionStandOptionsCodeDestination {
    let client: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>

    func forward(_ rec: CopyConcessionStandOptionsCodeRecord) async throws {
        _ = try await client.scheduleCarePlanExpiry(.with {
            $0.reason = rec.concessionStandID
            $0.details.step = rec.message
            $0.carePlan.number = rec.currencyCode
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CopyConcessionStandOptionsCodeLogOnly: CopyConcessionStandOptionsCodeDestination {
    let logger = Logger(label: "acme.copy-concession-stand-options-code")

    func forward(_ rec: CopyConcessionStandOptionsCodeRecord) async throws {
        logger.info("No sink for record", metadata: ["currencyCode": .string(rec.currencyCode)])
    }
}

/// Reads acme.concessions.v1.ConcessionStandCalculationService/CompareConcessionStandOptions and hands what it keeps to the sink of its kind.
enum CopyConcessionStandOptionsCode {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)
        let found = try await source.compareConcessionStandOptions(.with { $0.reason = "nightly-copy-concession-stand-options-code" })
        let entry = CopyConcessionStandOptionsCodeRecord(
            currencyCode: found.breakdown.currencyCode,
            message: found.result.message,
            concessionStandID: found.concessionStand.concessionStandID
        )
        try await deliver("care-plan-lifecycle", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CopyConcessionStandOptionsCodeRecord, _ mesh: MeshClient) async throws {
        var sink: any CopyConcessionStandOptionsCodeDestination = CopyConcessionStandOptionsCodeLogOnly()
        switch kind {
        case "care-goal-workflow":
            sink = CopyConcessionStandOptionsCodeCareGoalWorkflow(client: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh))
        case "notification-validation":
            sink = CopyConcessionStandOptionsCodeNotificationValidation(client: Acme_Notifications_V1_NotificationValidationService.Client(wrapping: mesh))
        case "care-plan-lifecycle":
            sink = CopyConcessionStandOptionsCodeCarePlanLifecycle(client: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
