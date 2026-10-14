import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushRecommendationSetNotes keeps of each UpdateRecommendationSet response.
struct PushRecommendationSetNotesRecord {
    var notes: String
    var number: String
    var status: String
    var message: String
}

/// Where PushRecommendationSetNotes hands each record.
protocol PushRecommendationSetNotesSink {
    func write(_ rec: PushRecommendationSetNotesRecord) async throws
}

/// Writes records to acme.careplans.v1.VitalLifecycleService.
struct PushRecommendationSetNotesVitalLifecycle: PushRecommendationSetNotesSink {
    let client: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>

    func write(_ rec: PushRecommendationSetNotesRecord) async throws {
        _ = try await client.terminateVital(.with {
            $0.details.reasonCode = rec.notes
            $0.vitalID = rec.status
            $0.reason = rec.message
        })
    }
}

/// Writes records to acme.patients.v1.AllergyReportingService.
struct PushRecommendationSetNotesAllergyReporting: PushRecommendationSetNotesSink {
    let client: Acme_Patients_V1_AllergyReportingService.Client<MeshTransport>

    func write(_ rec: PushRecommendationSetNotesRecord) async throws {
        _ = try await client.countAllergyTotals(.with {
            $0.filter.region = rec.number
            $0.filter.query = rec.status
        })
    }
}

/// Writes records to acme.payroll.v1.PayRunQueryService.
struct PushRecommendationSetNotesPayRunQuery: PushRecommendationSetNotesSink {
    let client: Acme_Payroll_V1_PayRunQueryService.Client<MeshTransport>

    func write(_ rec: PushRecommendationSetNotesRecord) async throws {
        let request = Acme_Payroll_V1_SuggestPayRunsRequest.with {
            $0.page.pageToken = rec.status
            $0.filter.region = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestPayRuns(request)
        }
    }
}

/// Reads acme.recommendations.v1.RecommendationSetService/UpdateRecommendationSet and hands what it keeps to the sink of its kind.
enum PushRecommendationSetNotes {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Recommendations_V1_RecommendationSetService.Client(wrapping: mesh)
        let response = try await upstream.updateRecommendationSet(.init())
        let rec = PushRecommendationSetNotesRecord(
            notes: response.recommendationSet.notes,
            number: Kit.Text.normalize(response.recommendationSet.number),
            status: response.result.status,
            message: response.result.message
        )
        let sinks: [any PushRecommendationSetNotesSink] = [
            PushRecommendationSetNotesVitalLifecycle(client: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: mesh)),
            PushRecommendationSetNotesAllergyReporting(client: Acme_Patients_V1_AllergyReportingService.Client(wrapping: mesh)),
            PushRecommendationSetNotesPayRunQuery(client: Acme_Payroll_V1_PayRunQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[2].write(rec)
    }
}
