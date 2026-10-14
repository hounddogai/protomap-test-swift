import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RoutePromotionID keeps of each QuotePromotion response.
struct RoutePromotionIDRecord {
    var correlationID: String
    var name: String
    var status: String
    var message: String
}

/// Where RoutePromotionID hands each record.
protocol RoutePromotionIDSink {
    func send(_ rec: RoutePromotionIDRecord) async throws
}

/// Sends records to acme.content.v1.ArticleQueryService.
struct RoutePromotionIDArticleQuery: RoutePromotionIDSink {
    let client: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>

    func send(_ rec: RoutePromotionIDRecord) async throws {
        let request = Acme_Content_V1_SummarizeArticlesRequest.with {
            $0.articleID = rec.name
            $0.details.format = rec.correlationID
            $0.details.cron = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.summarizeArticles(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.RefillSyncService.
struct RoutePromotionIDRefillSync: RoutePromotionIDSink {
    let client: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>

    func send(_ rec: RoutePromotionIDRecord) async throws {
        _ = try await client.resolveRefillConflict(.with {
            $0.details.checksum = rec.status
            $0.details.peerRegion = rec.message
        })
    }
}

/// Sends records to acme.appointments.v1.ProviderQueryService.
struct RoutePromotionIDProviderQuery: RoutePromotionIDSink {
    let client: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>

    func send(_ rec: RoutePromotionIDRecord) async throws {
        _ = try await client.browseProviders(.with {
            $0.filter.ownerID = rec.correlationID
            $0.page.pageToken = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RoutePromotionIDLogOnly: RoutePromotionIDSink {
    let logger = Logger(label: "acme.route-promotion-id")

    func send(_ rec: RoutePromotionIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.promotions.v1.PromotionCalculationService/QuotePromotion and hands what it keeps to the sink of its kind.
enum RoutePromotionID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Promotions_V1_PromotionCalculationService.Client(wrapping: mesh)
        let found = try await upstream.quotePromotion(.with { $0.reason = "current-route-promotion-id" })
        let row = RoutePromotionIDRecord(
            correlationID: found.result.correlationID,
            name: found.promotion.name,
            status: Kit.Text.normalize(found.result.status),
            message: found.result.message
        )
        try await dispatch("refill-sync", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RoutePromotionIDRecord, _ mesh: MeshClient) async throws {
        var write: (RoutePromotionIDRecord) async throws -> Void = RoutePromotionIDLogOnly().send
        switch kind {
        case "article-query":
            write = RoutePromotionIDArticleQuery(client: Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh)).send
        case "refill-sync":
            write = RoutePromotionIDRefillSync(client: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: mesh)).send
        case "provider-query":
            write = RoutePromotionIDProviderQuery(client: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: mesh)).send
        default:
            break
        }
        try await write(rec)
    }
}
