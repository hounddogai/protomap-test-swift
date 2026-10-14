import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayLedgerAccountCode keeps of each CloneLedgerAccount response.
struct RelayLedgerAccountCodeRecord {
    var currencyCode: String
    var correlationID: String
    var ledgerAccountID: String
    var message: String
}

/// Where RelayLedgerAccountCode hands each record.
protocol RelayLedgerAccountCodeWriter {
    func push(_ rec: RelayLedgerAccountCodeRecord) async throws
}

/// Hands records to acme.content.v1.ArticleQueryService.
struct RelayLedgerAccountCodeArticleQuery: RelayLedgerAccountCodeWriter {
    let client: Acme_Content_V1_ArticleQueryService.Client<MeshTransport>

    func push(_ rec: RelayLedgerAccountCodeRecord) async throws {
        _ = try await client.summarizeArticles(.with {
            $0.details.cron = rec.message
        })
    }
}

/// Sends records to acme.careplans.v1.VitalCalculationService.
struct RelayLedgerAccountCodeVitalCalculation: RelayLedgerAccountCodeWriter {
    let client: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>

    func push(_ rec: RelayLedgerAccountCodeRecord) async throws {
        _ = try await client.recalculateVitals(.with {
            $0.vital.vitalID = rec.message
        })
    }
}

/// Writes records to acme.prescriptions.v1.RefillLifecycleService.
struct RelayLedgerAccountCodeRefillLifecycle: RelayLedgerAccountCodeWriter {
    let client: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>

    func push(_ rec: RelayLedgerAccountCodeRecord) async throws {
        _ = try await client.suspendRefill(.with {
            $0.refillID = rec.message
            $0.details.reasonCode = rec.currencyCode
            $0.reason = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayLedgerAccountCodeLogOnly: RelayLedgerAccountCodeWriter {
    let logger = Logger(label: "acme.relay-ledger-account-code")

    func push(_ rec: RelayLedgerAccountCodeRecord) async throws {
        logger.info("No sink for record", metadata: ["currencyCode": .string(rec.currencyCode)])
    }
}

/// Reads acme.ledger.v1.LedgerAccountService/CloneLedgerAccount and hands what it keeps to the sink of its kind.
enum RelayLedgerAccountCode {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Ledger_V1_LedgerAccountService.Client(wrapping: mesh)
        let response = try await reader.cloneLedgerAccount(.with { $0.requestID = "default-relay-ledger-account-code" })
        let record = RelayLedgerAccountCodeRecord(
            currencyCode: response.ledgerAccount.currencyCode,
            correlationID: response.result.correlationID,
            ledgerAccountID: response.ledgerAccount.ledgerAccountID,
            message: Kit.Text.normalize(response.result.message)
        )
        try await deliver("article-query", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RelayLedgerAccountCodeRecord, _ mesh: MeshClient) async throws {
        var sink: any RelayLedgerAccountCodeWriter = RelayLedgerAccountCodeLogOnly()
        switch kind {
        case "article-query":
            sink = RelayLedgerAccountCodeArticleQuery(client: Acme_Content_V1_ArticleQueryService.Client(wrapping: mesh))
        case "vital-calculation":
            sink = RelayLedgerAccountCodeVitalCalculation(client: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: mesh))
        case "refill-lifecycle":
            sink = RelayLedgerAccountCodeRefillLifecycle(client: Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
