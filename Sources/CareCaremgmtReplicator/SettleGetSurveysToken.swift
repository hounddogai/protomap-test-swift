import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleGetSurveysToken keeps of each BatchGetSurveys response.
struct SettleGetSurveysTokenRecord {
    var nextPageToken: String
    var status: String
    var correlationID: String
}

/// Where SettleGetSurveysToken hands each record.
protocol SettleGetSurveysTokenTarget {
    func send(_ rec: SettleGetSurveysTokenRecord) async throws
}

/// Passes records to acme.localization.v1.TranslationKeyCalculationService.
struct SettleGetSurveysTokenTranslationKeyCalculation: SettleGetSurveysTokenTarget {
    let client: Acme_Localization_V1_TranslationKeyCalculationService.Client<MeshTransport>

    func send(_ rec: SettleGetSurveysTokenRecord) async throws {
        _ = try await client.compareTranslationKeyOptions(.with {
            $0.translationKey.translationKeyID = rec.status
        })
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitWorkflowService.
struct SettleGetSurveysTokenVideoVisitWorkflow: SettleGetSurveysTokenTarget {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func send(_ rec: SettleGetSurveysTokenRecord) async throws {
        _ = try await client.startVideoVisitWorkflow(.with {
            $0.videoVisitID = rec.correlationID
        })
    }
}

/// Hands records to acme.metrics.v1.MetricSeriesValidationService.
struct SettleGetSurveysTokenMetricSeriesValidation: SettleGetSurveysTokenTarget {
    let client: Acme_Metrics_V1_MetricSeriesValidationService.Client<MeshTransport>

    func send(_ rec: SettleGetSurveysTokenRecord) async throws {
        _ = try await client.lintMetricSerieses(.with {
            $0.metricSeries.name = rec.status
            $0.metricSeries.code = rec.correlationID
        })
    }
}

/// Hands records to acme.ledger.v1.LedgerAccountService.
struct SettleGetSurveysTokenLedgerAccount: SettleGetSurveysTokenTarget {
    let client: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>

    func send(_ rec: SettleGetSurveysTokenRecord) async throws {
        _ = try await client.createLedgerAccount(.with {
            $0.requestID = rec.correlationID
            $0.ledgerAccount.ledgerAccountID = rec.status
            $0.ledgerAccount.currencyCode = rec.nextPageToken
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleGetSurveysTokenLogOnly: SettleGetSurveysTokenTarget {
    let logger = Logger(label: "acme.settle-get-surveys-token")

    func send(_ rec: SettleGetSurveysTokenRecord) async throws {
        logger.info("No sink for record", metadata: ["nextPageToken": .string(rec.nextPageToken)])
    }
}

/// Reads acme.surveys.v1.SurveyService/BatchGetSurveys and hands what it keeps to the sink of its kind.
enum SettleGetSurveysToken {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Surveys_V1_SurveyService.Client(wrapping: mesh)
        let got = try await origin.batchGetSurveys(.init())
        let rec = SettleGetSurveysTokenRecord(
            nextPageToken: got.pageInfo.nextPageToken,
            status: got.result.status,
            correlationID: got.result.correlationID
        )
        try await dispatch("metric-series-validation", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SettleGetSurveysTokenRecord, _ mesh: MeshClient) async throws {
        var write: (SettleGetSurveysTokenRecord) async throws -> Void = SettleGetSurveysTokenLogOnly().send
        switch kind {
        case "translation-key-calculation":
            write = SettleGetSurveysTokenTranslationKeyCalculation(client: Acme_Localization_V1_TranslationKeyCalculationService.Client(wrapping: mesh)).send
        case "video-visit-workflow":
            write = SettleGetSurveysTokenVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)).send
        case "metric-series-validation":
            write = SettleGetSurveysTokenMetricSeriesValidation(client: Acme_Metrics_V1_MetricSeriesValidationService.Client(wrapping: mesh)).send
        case "ledger-account":
            write = SettleGetSurveysTokenLedgerAccount(client: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: mesh)).send
        default:
            break
        }
        try await write(rec)
    }
}
