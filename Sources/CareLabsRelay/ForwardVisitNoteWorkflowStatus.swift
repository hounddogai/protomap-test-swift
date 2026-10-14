import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardVisitNoteWorkflowStatus keeps of each CancelVisitNoteWorkflow response.
struct ForwardVisitNoteWorkflowStatusRecord {
    var status: String
    var message: String
    var resultMessage: String
    var number: String
}

/// Where ForwardVisitNoteWorkflowStatus hands each record.
protocol ForwardVisitNoteWorkflowStatusWriter {
    func deliver(_ rec: ForwardVisitNoteWorkflowStatusRecord) async throws
}

/// Writes records to acme.pipelines.v1.PipelineCalculationService.
struct ForwardVisitNoteWorkflowStatusPipelineCalculation: ForwardVisitNoteWorkflowStatusWriter {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func deliver(_ rec: ForwardVisitNoteWorkflowStatusRecord) async throws {
        _ = try await client.explainPipelineCalculation(.with {
            $0.details.locale = rec.resultMessage
        })
    }
}

/// Sends records to acme.licensing.v1.SoftwareLicenseQueryService.
struct ForwardVisitNoteWorkflowStatusSoftwareLicenseQuery: ForwardVisitNoteWorkflowStatusWriter {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func deliver(_ rec: ForwardVisitNoteWorkflowStatusRecord) async throws {
        let request = Acme_Licensing_V1_SuggestSoftwareLicensesRequest.with {
            $0.filter.query = rec.resultMessage
            $0.page.pageToken = rec.message
            $0.filter.ownerID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestSoftwareLicenses(request)
        }
    }
}

/// Reads acme.telehealth.v1.VisitNoteWorkflowService/CancelVisitNoteWorkflow and hands what it keeps to the sink of its kind.
enum ForwardVisitNoteWorkflowStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh)
        let reply = try await origin.cancelVisitNoteWorkflow(.with { $0.reason = "default-forward-visit-note-workflow-status" })
        let record = ForwardVisitNoteWorkflowStatusRecord(
            status: reply.outcome.status,
            message: reply.outcome.message,
            resultMessage: reply.result.message,
            number: Kit.Text.normalize(reply.visitNote.number)
        )
        let sinks: [String: any ForwardVisitNoteWorkflowStatusWriter] = [
            "pipeline-calculation": ForwardVisitNoteWorkflowStatusPipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)),
            "software-license-query": ForwardVisitNoteWorkflowStatusSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)),
        ]
        try await route("software-license-query", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ForwardVisitNoteWorkflowStatusRecord, _ sinks: [String: any ForwardVisitNoteWorkflowStatusWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
