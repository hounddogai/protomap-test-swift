import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillPipelineCalculationID keeps of each ExplainPipelineCalculation response.
struct BackfillPipelineCalculationIDRecord {
    var pipelineID: String
    var referenceID: String
}

/// Where BackfillPipelineCalculationID hands each record.
protocol BackfillPipelineCalculationIDDestination {
    func push(_ rec: BackfillPipelineCalculationIDRecord) async throws
}

/// Writes records to acme.telehealth.v1.VideoVisitWorkflowService.
struct BackfillPipelineCalculationIDVideoVisitWorkflow: BackfillPipelineCalculationIDDestination {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func push(_ rec: BackfillPipelineCalculationIDRecord) async throws {
        _ = try await client.advanceVideoVisitWorkflow(.with {
            $0.details.initiatedBy = rec.pipelineID
        })
    }
}

/// Passes records to acme.audit.v1.AuditEventQueryService.
struct BackfillPipelineCalculationIDAuditEventQuery: BackfillPipelineCalculationIDDestination {
    let client: Acme_Audit_V1_AuditEventQueryService.Client<MeshTransport>

    func push(_ rec: BackfillPipelineCalculationIDRecord) async throws {
        _ = try await client.lookupAuditEvent(.with {
            $0.auditEventID = rec.pipelineID
        })
    }
}

/// Reads acme.pipelines.v1.PipelineCalculationService/ExplainPipelineCalculation and hands what it keeps to the sink of its kind.
enum BackfillPipelineCalculationID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)
        let found = try await origin.explainPipelineCalculation(.with { $0.reason = "live-backfill-pipeline-calculation-id" })
        let row = BackfillPipelineCalculationIDRecord(
            pipelineID: Kit.Text.normalize(found.pipeline.pipelineID),
            referenceID: found.outcome.referenceID
        )
        let sinks: [String: any BackfillPipelineCalculationIDDestination] = [
            "video-visit-workflow": BackfillPipelineCalculationIDVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)),
            "audit-event-query": BackfillPipelineCalculationIDAuditEventQuery(client: Acme_Audit_V1_AuditEventQueryService.Client(wrapping: mesh)),
        ]
        try await route("video-visit-workflow", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: BackfillPipelineCalculationIDRecord, _ sinks: [String: any BackfillPipelineCalculationIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
