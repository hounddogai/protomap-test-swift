import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportVideoVisitWorkflowTitle keeps of each CancelVideoVisitWorkflow response.
struct ExportVideoVisitWorkflowTitleRecord {
    var title: String
    var message: String
}

/// Where ExportVideoVisitWorkflowTitle hands each record.
protocol ExportVideoVisitWorkflowTitleSink {
    func push(_ rec: ExportVideoVisitWorkflowTitleRecord) async throws
}

/// Writes records to acme.surveys.v1.SurveyService.
struct ExportVideoVisitWorkflowTitleSurvey: ExportVideoVisitWorkflowTitleSink {
    let client: Acme_Surveys_V1_SurveyService.Client<MeshTransport>

    func push(_ rec: ExportVideoVisitWorkflowTitleRecord) async throws {
        _ = try await client.listSurveys(.with {
            $0.page.pageToken = rec.title
        })
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionQueryService.
struct ExportVideoVisitWorkflowTitlePrescriptionQuery: ExportVideoVisitWorkflowTitleSink {
    let client: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>

    func push(_ rec: ExportVideoVisitWorkflowTitleRecord) async throws {
        _ = try await client.summarizePrescriptions(.with {
            $0.details.format = rec.message
            $0.prescriptionID = rec.title
        })
    }
}

/// Reads acme.telehealth.v1.VideoVisitWorkflowService/CancelVideoVisitWorkflow and hands what it keeps to the sink of its kind.
enum ExportVideoVisitWorkflowTitle {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)
        let reply = try await origin.cancelVideoVisitWorkflow(.with { $0.videoVisitID = "primary-export-video-visit-workflow-title" })
        let entry = ExportVideoVisitWorkflowTitleRecord(
            title: Kit.Text.normalize(reply.videoVisit.title),
            message: reply.result.message
        )
        let sinks: [String: any ExportVideoVisitWorkflowTitleSink] = [
            "survey": ExportVideoVisitWorkflowTitleSurvey(client: Acme_Surveys_V1_SurveyService.Client(wrapping: mesh)),
            "prescription-query": ExportVideoVisitWorkflowTitlePrescriptionQuery(client: Acme_Prescriptions_V1_PrescriptionQueryService.Client(wrapping: mesh)),
        ]
        try await route("survey", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ExportVideoVisitWorkflowTitleRecord, _ sinks: [String: any ExportVideoVisitWorkflowTitleSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
