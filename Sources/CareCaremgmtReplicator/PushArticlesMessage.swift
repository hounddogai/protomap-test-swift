import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushArticlesMessage keeps of each CountArticles response.
struct PushArticlesMessageRecord {
    var message: String
    var status: String
    var correlationID: String
}

/// Where PushArticlesMessage hands each record.
protocol PushArticlesMessageSink {
    func forward(_ rec: PushArticlesMessageRecord) async throws
}

/// Writes records to acme.telehealth.v1.VisitNoteCalculationService.
struct PushArticlesMessageVisitNoteCalculation: PushArticlesMessageSink {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func forward(_ rec: PushArticlesMessageRecord) async throws {
        _ = try await client.calculateVisitNote(.with {
            $0.visitNote.number = rec.status
            $0.visitNote.notes = rec.message
        })
    }
}

/// Writes records to acme.surveys.v1.SurveyService.
struct PushArticlesMessageSurvey: PushArticlesMessageSink {
    let client: Acme_Surveys_V1_SurveyService.Client<MeshTransport>

    func forward(_ rec: PushArticlesMessageRecord) async throws {
        let request = Acme_Surveys_V1_GetSurveyRequest.with {
            $0.surveyID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getSurvey(request)
        }
    }
}

/// Sends records to acme.metrics.v1.MetricSeriesQueryService.
struct PushArticlesMessageMetricSeriesQuery: PushArticlesMessageSink {
    let client: Acme_Metrics_V1_MetricSeriesQueryService.Client<MeshTransport>

    func forward(_ rec: PushArticlesMessageRecord) async throws {
        let request = Acme_Metrics_V1_SuggestMetricSeriesesRequest.with {
            $0.filter.ownerID = rec.message
            $0.orderBy = rec.status
            $0.filter.query = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestMetricSerieses(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PushArticlesMessageLogOnly: PushArticlesMessageSink {
    let logger = Logger(label: "acme.push-articles-message")

    func forward(_ rec: PushArticlesMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.content.v1.ArticleQueryService/CountArticles and hands what it keeps to the sink of its kind.
enum PushArticlesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh)
        let reply = try await source.countArticles(.with { $0.orderBy = "nightly-push-articles-message" })
        let rec = PushArticlesMessageRecord(
            message: reply.result.message,
            status: Kit.Text.normalize(reply.result.status),
            correlationID: reply.result.correlationID
        )
        try await deliver("visit-note-calculation", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PushArticlesMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any PushArticlesMessageSink = PushArticlesMessageLogOnly()
        switch kind {
        case "visit-note-calculation":
            sink = PushArticlesMessageVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh))
        case "survey":
            sink = PushArticlesMessageSurvey(client: Acme_Surveys_V1_SurveyService.Client(wrapping: mesh))
        case "metric-series-query":
            sink = PushArticlesMessageMetricSeriesQuery(client: Acme_Metrics_V1_MetricSeriesQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
