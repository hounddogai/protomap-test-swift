import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillVideoVisitWorkflowMessage keeps of each RetryVideoVisitWorkflow response.
struct BackfillVideoVisitWorkflowMessageRecord {
    var message: String
    var videoVisitID: String
}

/// Sends records to acme.patientapp.v1.CareInboxQueryService.
struct BackfillVideoVisitWorkflowMessageCareInboxQuery {
    let client: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>

    func push(_ rec: BackfillVideoVisitWorkflowMessageRecord) async throws {
        _ = try await client.summarizeCareInboxes(.with {
            $0.details.format = rec.videoVisitID
            $0.details.cron = rec.message
        })
    }
}

/// Reads acme.telehealth.v1.VideoVisitWorkflowService/RetryVideoVisitWorkflow and hands what it keeps to acme.patientapp.v1.CareInboxQueryService.
enum BackfillVideoVisitWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)
        let response = try await source.retryVideoVisitWorkflow(.with { $0.videoVisitID = "live-backfill-video-visit-workflow-message" })
        let rec = BackfillVideoVisitWorkflowMessageRecord(
            message: Kit.Text.normalize(response.outcome.message),
            videoVisitID: response.videoVisit.videoVisitID
        )
        try await BackfillVideoVisitWorkflowMessageCareInboxQuery(client: Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: mesh)).push(rec)
    }
}
