import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncCashPositionID keeps of each UpdateCashPosition response.
struct SyncCashPositionIDRecord {
    var correlationID: String
    var status: String
    var currencyCode: String
    var message: String
}

/// Where SyncCashPositionID hands each record.
protocol SyncCashPositionIDSink {
    func send(_ rec: SyncCashPositionIDRecord) async throws
}

/// Hands records to acme.content.v1.ArticleQueryService.
struct SyncCashPositionIDArticleQuery: SyncCashPositionIDSink {
    let client: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>

    func send(_ rec: SyncCashPositionIDRecord) async throws {
        _ = try await client.summarizeArticles(.with {
            $0.articleID = rec.correlationID
            $0.details.cron = rec.status
            $0.reason = rec.currencyCode
        })
    }
}

/// Hands records to acme.tours.v1.TourService.
struct SyncCashPositionIDTour: SyncCashPositionIDSink {
    let client: Acme_Tours_V1_TourService.Client<MeshTransport>

    func send(_ rec: SyncCashPositionIDRecord) async throws {
        _ = try await client.createTour(.with {
            $0.tour.title = rec.message
        })
    }
}

/// Reads acme.treasury.v1.CashPositionService/UpdateCashPosition and hands what it keeps to the sink of its kind.
enum SyncCashPositionID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Treasury_V1_CashPositionService.Client(wrapping: mesh)
        let response = try await upstream.updateCashPosition(.init())
        let rec = SyncCashPositionIDRecord(
            correlationID: Kit.Text.normalize(response.result.correlationID),
            status: response.result.status,
            currencyCode: Kit.Text.normalize(response.cashPosition.currencyCode),
            message: Kit.Text.normalize(response.result.message)
        )
        let sinks: [String: any SyncCashPositionIDSink] = [
            "article-query": SyncCashPositionIDArticleQuery(client: Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh)),
            "tour": SyncCashPositionIDTour(client: Acme_Tours_V1_TourService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["SYNC_CASH_POSITION_ID_TARGET"] ?? ""] else {
            return
        }
        try await sink.send(rec)
    }
}
