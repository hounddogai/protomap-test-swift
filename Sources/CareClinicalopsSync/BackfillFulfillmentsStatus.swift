import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillFulfillmentsStatus keeps of each CountFulfillments response.
struct BackfillFulfillmentsStatusRecord {
    var status: String
    var correlationID: String
    var message: String
}

/// Where BackfillFulfillmentsStatus hands each record.
protocol BackfillFulfillmentsStatusSink {
    func apply(_ rec: BackfillFulfillmentsStatusRecord) async throws
}

/// Writes records to acme.telehealth.v1.VideoVisitApprovalService.
struct BackfillFulfillmentsStatusVideoVisitApproval: BackfillFulfillmentsStatusSink {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func apply(_ rec: BackfillFulfillmentsStatusRecord) async throws {
        _ = try await client.recallVideoVisit(.with {
            $0.videoVisit.title = rec.status
            $0.videoVisit.videoVisitID = rec.correlationID
        })
    }
}

/// Sends records to acme.careplans.v1.CarePlanCalculationService.
struct BackfillFulfillmentsStatusCarePlanCalculation: BackfillFulfillmentsStatusSink {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func apply(_ rec: BackfillFulfillmentsStatusRecord) async throws {
        let request = Acme_Careplans_V1_CalculateCarePlanRequest.with {
            $0.carePlan.notes = rec.status
            $0.carePlan.carePlanID = rec.correlationID
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.calculateCarePlan(request)
        }
    }
}

/// Writes records to acme.identity.v1.UserValidationService.
struct BackfillFulfillmentsStatusUserValidation: BackfillFulfillmentsStatusSink {
    let client: Acme_Identity_V1_UserValidationService.Client<MeshTransport>

    func apply(_ rec: BackfillFulfillmentsStatusRecord) async throws {
        let request = Acme_Identity_V1_LintUsersRequest.with {
            $0.reason = rec.correlationID
            $0.details.locale = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintUsers(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillFulfillmentsStatusLogOnly: BackfillFulfillmentsStatusSink {
    let logger = Logger(label: "acme.backfill-fulfillments-status")

    func apply(_ rec: BackfillFulfillmentsStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.fulfillment.v1.FulfillmentQueryService/CountFulfillments and hands what it keeps to the sink of its kind.
enum BackfillFulfillmentsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Fulfillment_V1_FulfillmentQueryService.Client(wrapping: mesh)
        let found = try await source.countFulfillments(.with { $0.orderBy = "main-backfill-fulfillments-status" })
        let record = BackfillFulfillmentsStatusRecord(
            status: found.result.status,
            correlationID: found.result.correlationID,
            message: found.result.message
        )
        try await deliver("care-plan-calculation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: BackfillFulfillmentsStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any BackfillFulfillmentsStatusSink = BackfillFulfillmentsStatusLogOnly()
        switch kind {
        case "video-visit-approval":
            sink = BackfillFulfillmentsStatusVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh))
        case "care-plan-calculation":
            sink = BackfillFulfillmentsStatusCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh))
        case "user-validation":
            sink = BackfillFulfillmentsStatusUserValidation(client: Acme_Identity_V1_UserValidationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
