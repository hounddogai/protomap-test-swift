import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillCareGoalsTimezone keeps of each SummarizeCareGoals response.
struct BackfillCareGoalsTimezoneRecord {
    var timezone: String
    var reportID: String
    var downloadUri: String
    var message: String
}

/// Where BackfillCareGoalsTimezone hands each record.
protocol BackfillCareGoalsTimezoneSink {
    func write(_ rec: BackfillCareGoalsTimezoneRecord) async throws
}

/// Writes records to acme.telehealth.v1.TriageWorkflowService.
struct BackfillCareGoalsTimezoneTriageWorkflow: BackfillCareGoalsTimezoneSink {
    let client: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>

    func write(_ rec: BackfillCareGoalsTimezoneRecord) async throws {
        _ = try await client.startTriageWorkflow(.with {
            $0.triage.subject = rec.message
            $0.details.step = rec.downloadUri
        })
    }
}

/// Sends records to acme.telehealth.v1.VisitNoteValidationService.
struct BackfillCareGoalsTimezoneVisitNoteValidation: BackfillCareGoalsTimezoneSink {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func write(_ rec: BackfillCareGoalsTimezoneRecord) async throws {
        _ = try await client.explainVisitNoteDecision(.with {
            $0.visitNoteID = rec.reportID
        })
    }
}

/// Reads acme.careplans.v1.CareGoalQueryService/SummarizeCareGoals and hands what it keeps to the sink of its kind.
enum BackfillCareGoalsTimezone {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh)
        let response = try await source.summarizeCareGoals(.with { $0.reason = "live-backfill-care-goals-timezone" })
        let rec = BackfillCareGoalsTimezoneRecord(
            timezone: response.period.timezone,
            reportID: response.reportID,
            downloadUri: response.downloadUri,
            message: response.result.message
        )
        let sinks: [String: any BackfillCareGoalsTimezoneSink] = [
            "triage-workflow": BackfillCareGoalsTimezoneTriageWorkflow(client: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)),
            "visit-note-validation": BackfillCareGoalsTimezoneVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "visit-note-validation" {
                continue
            }
            try await sink.write(rec)
        }
    }
}
