import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorRefillMessage keeps of each ExpireRefill response.
struct MirrorRefillMessageRecord {
    var message: String
    var correlationID: String
    var outcomeMessage: String
}

/// Where MirrorRefillMessage hands each record.
protocol MirrorRefillMessageWriter {
    func forward(_ rec: MirrorRefillMessageRecord) async throws
}

/// Passes records to acme.careplans.v1.CareGoalLifecycleService.
struct MirrorRefillMessageCareGoalLifecycle: MirrorRefillMessageWriter {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func forward(_ rec: MirrorRefillMessageRecord) async throws {
        let request = Acme_Careplans_V1_ExpireCareGoalRequest.with {
            $0.details.reasonCode = rec.message
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.expireCareGoal(request)
        }
    }
}

/// Sends records to acme.careplans.v1.VitalApprovalService.
struct MirrorRefillMessageVitalApproval: MirrorRefillMessageWriter {
    let client: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>

    func forward(_ rec: MirrorRefillMessageRecord) async throws {
        let request = Acme_Careplans_V1_GetVitalApprovalStatusRequest.with {
            $0.vitalID = rec.outcomeMessage
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getVitalApprovalStatus(request)
        }
    }
}

/// Writes records to acme.configuration.v1.ConfigSetService.
struct MirrorRefillMessageConfigSet: MirrorRefillMessageWriter {
    let client: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>

    func forward(_ rec: MirrorRefillMessageRecord) async throws {
        let request = Acme_Configuration_V1_UpdateConfigSetRequest.with {
            $0.configSet.name = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateConfigSet(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct MirrorRefillMessageLogOnly: MirrorRefillMessageWriter {
    let logger = Logger(label: "acme.mirror-refill-message")

    func forward(_ rec: MirrorRefillMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.prescriptions.v1.RefillLifecycleService/ExpireRefill and hands what it keeps to the sink of its kind.
enum MirrorRefillMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh)
        let reply = try await reader.expireRefill(.with { $0.refillID = "live-mirror-refill-message" })
        let rec = MirrorRefillMessageRecord(
            message: reply.result.message,
            correlationID: reply.result.correlationID,
            outcomeMessage: reply.outcome.message
        )
        try await deliver("care-goal-lifecycle", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: MirrorRefillMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any MirrorRefillMessageWriter = MirrorRefillMessageLogOnly()
        switch kind {
        case "care-goal-lifecycle":
            sink = MirrorRefillMessageCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh))
        case "vital-approval":
            sink = MirrorRefillMessageVitalApproval(client: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh))
        case "config-set":
            sink = MirrorRefillMessageConfigSet(client: Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
