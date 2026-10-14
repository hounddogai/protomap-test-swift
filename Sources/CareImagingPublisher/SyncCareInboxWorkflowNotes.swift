import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncCareInboxWorkflowNotes keeps of each PauseCareInboxWorkflow response.
struct SyncCareInboxWorkflowNotesRecord {
    var notes: String
    var message: String
    var number: String
}

/// Where SyncCareInboxWorkflowNotes hands each record.
protocol SyncCareInboxWorkflowNotesSink {
    func push(_ rec: SyncCareInboxWorkflowNotesRecord) async throws
}

/// Writes records to acme.pipelines.v1.PipelineCalculationService.
struct SyncCareInboxWorkflowNotesPipelineCalculation: SyncCareInboxWorkflowNotesSink {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func push(_ rec: SyncCareInboxWorkflowNotesRecord) async throws {
        _ = try await client.recalculatePipelines(.with {
            $0.pipelineID = rec.notes
        })
    }
}

/// Passes records to acme.careplans.v1.VitalApprovalService.
struct SyncCareInboxWorkflowNotesVitalApproval: SyncCareInboxWorkflowNotesSink {
    let client: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>

    func push(_ rec: SyncCareInboxWorkflowNotesRecord) async throws {
        let request = Acme_Careplans_V1_CommentVitalApprovalRequest.with {
            $0.vital.kind = rec.notes
            $0.details.approverEmail = rec.number
            $0.vital.vitalID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.commentVitalApproval(request)
        }
    }
}

/// Passes records to acme.patientapp.v1.CareInboxWorkflowService.
struct SyncCareInboxWorkflowNotesCareInboxWorkflow: SyncCareInboxWorkflowNotesSink {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func push(_ rec: SyncCareInboxWorkflowNotesRecord) async throws {
        let request = Acme_Patientapp_V1_ResumeCareInboxWorkflowRequest.with {
            $0.careInbox.careInboxID = rec.number
            $0.careInbox.notes = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.resumeCareInboxWorkflow(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncCareInboxWorkflowNotesLogOnly: SyncCareInboxWorkflowNotesSink {
    let logger = Logger(label: "acme.sync-care-inbox-workflow-notes")

    func push(_ rec: SyncCareInboxWorkflowNotesRecord) async throws {
        logger.info("No sink for record", metadata: ["notes": .string(rec.notes)])
    }
}

/// Reads acme.patientapp.v1.CareInboxWorkflowService/PauseCareInboxWorkflow and hands what it keeps to the sink of its kind.
enum SyncCareInboxWorkflowNotes {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)
        let got = try await origin.pauseCareInboxWorkflow(.with { $0.careInboxID = "live-sync-care-inbox-workflow-notes" })
        let row = SyncCareInboxWorkflowNotesRecord(
            notes: got.careInbox.notes,
            message: got.result.message,
            number: got.careInbox.number
        )
        try await dispatch("care-inbox-workflow", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SyncCareInboxWorkflowNotesRecord, _ mesh: MeshClient) async throws {
        var write: (SyncCareInboxWorkflowNotesRecord) async throws -> Void = SyncCareInboxWorkflowNotesLogOnly().push
        switch kind {
        case "pipeline-calculation":
            write = SyncCareInboxWorkflowNotesPipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)).push
        case "vital-approval":
            write = SyncCareInboxWorkflowNotesVitalApproval(client: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)).push
        case "care-inbox-workflow":
            write = SyncCareInboxWorkflowNotesCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
