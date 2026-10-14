import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillChartOfAccountsesID keeps of each ListChartOfAccountses response.
struct BackfillChartOfAccountsesIDRecord {
    var correlationID: String
    var status: String
    var nextPageToken: String
}

/// Where BackfillChartOfAccountsesID hands each record.
protocol BackfillChartOfAccountsesIDWriter {
    func write(_ rec: BackfillChartOfAccountsesIDRecord) async throws
}

/// Sends records to acme.featureflags.v1.FeatureFlagValidationService.
struct BackfillChartOfAccountsesIDFeatureFlagValidation: BackfillChartOfAccountsesIDWriter {
    let client: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>

    func write(_ rec: BackfillChartOfAccountsesIDRecord) async throws {
        _ = try await client.getFeatureFlagRules(.with {
            $0.featureFlagID = rec.nextPageToken
        })
    }
}

/// Sends records to acme.featureflags.v1.FeatureFlagQueryService.
struct BackfillChartOfAccountsesIDFeatureFlagQuery: BackfillChartOfAccountsesIDWriter {
    let client: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>

    func write(_ rec: BackfillChartOfAccountsesIDRecord) async throws {
        let request = Acme_Featureflags_V1_LookupFeatureFlagRequest.with {
            $0.featureFlagID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupFeatureFlag(request)
        }
    }
}

/// Writes records to acme.catalog.v1.ProductCalculationService.
struct BackfillChartOfAccountsesIDProductCalculation: BackfillChartOfAccountsesIDWriter {
    let client: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>

    func write(_ rec: BackfillChartOfAccountsesIDRecord) async throws {
        _ = try await client.explainProductCalculation(.with {
            $0.reason = rec.status
            $0.product.productID = rec.nextPageToken
        })
    }
}

/// Hands records to acme.yards.v1.YardCalculationService.
struct BackfillChartOfAccountsesIDYardCalculation: BackfillChartOfAccountsesIDWriter {
    let client: Acme_Yards_V1_YardCalculationService.Client<MeshTransport>

    func write(_ rec: BackfillChartOfAccountsesIDRecord) async throws {
        _ = try await client.getYardRates(.with {
            $0.yardID = rec.nextPageToken
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillChartOfAccountsesIDLogOnly: BackfillChartOfAccountsesIDWriter {
    let logger = Logger(label: "acme.backfill-chart-of-accountses-id")

    func write(_ rec: BackfillChartOfAccountsesIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.accounting.v1.ChartOfAccountsService/ListChartOfAccountses and hands what it keeps to the sink of its kind.
enum BackfillChartOfAccountsesID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh)
        let found = try await upstream.listChartOfAccountses(.with { $0.orderBy = "live-backfill-chart-of-accountses-id" })
        let record = BackfillChartOfAccountsesIDRecord(
            correlationID: found.result.correlationID,
            status: Kit.Text.normalize(found.result.status),
            nextPageToken: found.pageInfo.nextPageToken
        )
        try await dispatch("product-calculation", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: BackfillChartOfAccountsesIDRecord, _ mesh: MeshClient) async throws {
        var write: (BackfillChartOfAccountsesIDRecord) async throws -> Void = BackfillChartOfAccountsesIDLogOnly().write
        switch kind {
        case "feature-flag-validation":
            write = BackfillChartOfAccountsesIDFeatureFlagValidation(client: Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh)).write
        case "feature-flag-query":
            write = BackfillChartOfAccountsesIDFeatureFlagQuery(client: Acme_Featureflags_V1_FeatureFlagQueryService.Client(wrapping: mesh)).write
        case "product-calculation":
            write = BackfillChartOfAccountsesIDProductCalculation(client: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh)).write
        case "yard-calculation":
            write = BackfillChartOfAccountsesIDYardCalculation(client: Acme_Yards_V1_YardCalculationService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
