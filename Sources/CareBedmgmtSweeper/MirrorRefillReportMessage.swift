import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorRefillReportMessage keeps of each ShareRefillReport response.
struct MirrorRefillReportMessageRecord {
    var message: String
    var refillID: String
}

/// Where MirrorRefillReportMessage hands each record.
protocol MirrorRefillReportMessageTarget {
    func write(_ rec: MirrorRefillReportMessageRecord) async throws
}

/// Sends records to acme.careplans.v1.CareGoalLifecycleService.
struct MirrorRefillReportMessageCareGoalLifecycle: MirrorRefillReportMessageTarget {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func write(_ rec: MirrorRefillReportMessageRecord) async throws {
        let request = Acme_Careplans_V1_ActivateCareGoalRequest.with {
            $0.reason = rec.message
            $0.careGoalID = rec.refillID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.activateCareGoal(request)
        }
    }
}

/// Sends records to acme.pipelines.v1.PipelineCalculationService.
struct MirrorRefillReportMessagePipelineCalculation: MirrorRefillReportMessageTarget {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func write(_ rec: MirrorRefillReportMessageRecord) async throws {
        _ = try await client.calculatePipeline(.with {
            $0.pipeline.pipelineID = rec.refillID
        })
    }
}

/// Reads acme.prescriptions.v1.RefillReportingService/ShareRefillReport and hands what it keeps to the sink of its kind.
enum MirrorRefillReportMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_RefillReportingService.Client(wrapping: mesh)
        let found = try await origin.shareRefillReport(.with { $0.reason = "primary-mirror-refill-report-message" })
        let record = MirrorRefillReportMessageRecord(
            message: found.outcome.message,
            refillID: Kit.Text.normalize(found.refill.refillID)
        )
        try await act("pipeline-calculation", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: MirrorRefillReportMessageRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "care-goal-lifecycle": { try await MirrorRefillReportMessageCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)).write(rec) },
            "pipeline-calculation": { try await MirrorRefillReportMessagePipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
