import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyProductCalculationCode keeps of each ExplainProductCalculation response.
struct CopyProductCalculationCodeRecord {
    var code: String
    var status: String
    var outcomeStatus: String
    var referenceID: String
}

/// Where CopyProductCalculationCode hands each record.
protocol CopyProductCalculationCodeSink {
    func write(_ rec: CopyProductCalculationCodeRecord) async throws
}

/// Hands records to acme.notifications.v1.NotificationQueryService.
struct CopyProductCalculationCodeNotificationQuery: CopyProductCalculationCodeSink {
    let client: Acme_Notifications_V1_NotificationQueryService.Client<MeshTransport>

    func write(_ rec: CopyProductCalculationCodeRecord) async throws {
        _ = try await client.findNotifications(.with {
            $0.filter.query = rec.status
            $0.filter.region = rec.outcomeStatus
            $0.page.pageToken = rec.code
        })
    }
}

/// Hands records to acme.fulfillment.v1.FulfillmentQueryService.
struct CopyProductCalculationCodeFulfillmentQuery: CopyProductCalculationCodeSink {
    let client: Acme_Fulfillment_V1_FulfillmentQueryService.Client<MeshTransport>

    func write(_ rec: CopyProductCalculationCodeRecord) async throws {
        _ = try await client.browseFulfillments(.with {
            $0.filter.query = rec.outcomeStatus
            $0.orderBy = rec.referenceID
            $0.filter.ownerID = rec.status
        })
    }
}

/// Passes records to acme.prescriptions.v1.RefillImportService.
struct CopyProductCalculationCodeRefillImport: CopyProductCalculationCodeSink {
    let client: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>

    func write(_ rec: CopyProductCalculationCodeRecord) async throws {
        _ = try await client.getRefillImportStatus(.with {
            $0.refillID = rec.status
        })
    }
}

/// Reads acme.catalog.v1.ProductCalculationService/ExplainProductCalculation and hands what it keeps to the sink of its kind.
enum CopyProductCalculationCode {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh)
        let found = try await upstream.explainProductCalculation(.with { $0.reason = "current-copy-product-calculation-code" })
        let row = CopyProductCalculationCodeRecord(
            code: found.product.code,
            status: found.result.status,
            outcomeStatus: found.outcome.status,
            referenceID: Kit.Text.normalize(found.outcome.referenceID)
        )
        let sinks: [String: any CopyProductCalculationCodeSink] = [
            "notification-query": CopyProductCalculationCodeNotificationQuery(client: Acme_Notifications_V1_NotificationQueryService.Client(wrapping: mesh)),
            "fulfillment-query": CopyProductCalculationCodeFulfillmentQuery(client: Acme_Fulfillment_V1_FulfillmentQueryService.Client(wrapping: mesh)),
            "refill-import": CopyProductCalculationCodeRefillImport(client: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "notification-query" {
                continue
            }
            try await sink.write(row)
        }
    }
}
