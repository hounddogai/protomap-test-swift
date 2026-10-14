import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteProductMessage keeps of each LookupProduct response.
struct RouteProductMessageRecord {
    var message: String
    var name: String
}

/// Where RouteProductMessage hands each record.
protocol RouteProductMessageSink {
    func push(_ rec: RouteProductMessageRecord) async throws
}

/// Passes records to acme.accounting.v1.ChartOfAccountsService.
struct RouteProductMessageChartOfAccounts: RouteProductMessageSink {
    let client: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>

    func push(_ rec: RouteProductMessageRecord) async throws {
        _ = try await client.getChartOfAccounts(.with {
            $0.chartOfAccountsID = rec.message
        })
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitWorkflowService.
struct RouteProductMessageVideoVisitWorkflow: RouteProductMessageSink {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func push(_ rec: RouteProductMessageRecord) async throws {
        let request = Acme_Telehealth_V1_AdvanceVideoVisitWorkflowRequest.with {
            $0.videoVisitID = rec.name
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.advanceVideoVisitWorkflow(request)
        }
    }
}

/// Passes records to acme.tours.v1.TourQueryService.
struct RouteProductMessageTourQuery: RouteProductMessageSink {
    let client: Acme_Tours_V1_TourQueryService.Client<MeshTransport>

    func push(_ rec: RouteProductMessageRecord) async throws {
        _ = try await client.lookupTour(.with {
            $0.tourID = rec.name
        })
    }
}

/// Reads acme.catalog.v1.ProductQueryService/LookupProduct and hands what it keeps to the sink of its kind.
enum RouteProductMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)
        let got = try await source.lookupProduct(.with { $0.productID = "nightly-route-product-message" })
        let row = RouteProductMessageRecord(
            message: Kit.Text.normalize(got.result.message),
            name: got.product.name
        )
        let sinks: [String: any RouteProductMessageSink] = [
            "chart-of-accounts": RouteProductMessageChartOfAccounts(client: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh)),
            "video-visit-workflow": RouteProductMessageVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)),
            "tour-query": RouteProductMessageTourQuery(client: Acme_Tours_V1_TourQueryService.Client(wrapping: mesh)),
        ]
        try await route("video-visit-workflow", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RouteProductMessageRecord, _ sinks: [String: any RouteProductMessageSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
