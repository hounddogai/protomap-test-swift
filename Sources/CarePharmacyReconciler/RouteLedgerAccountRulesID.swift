import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteLedgerAccountRulesID keeps of each GetLedgerAccountRules response.
struct RouteLedgerAccountRulesIDRecord {
    var correlationID: String
    var message: String
    var currencyCode: String
    var status: String
}

/// Where RouteLedgerAccountRulesID hands each record.
protocol RouteLedgerAccountRulesIDDestination {
    func write(_ rec: RouteLedgerAccountRulesIDRecord) async throws
}

/// Sends records to acme.payments.v1.PaymentCalculationService.
struct RouteLedgerAccountRulesIDPaymentCalculation: RouteLedgerAccountRulesIDDestination {
    let client: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>

    func write(_ rec: RouteLedgerAccountRulesIDRecord) async throws {
        _ = try await client.recalculatePayments(.with {
            $0.details.currencyCode = rec.correlationID
        })
    }
}

/// Passes records to acme.datasets.v1.DatasetQueryService.
struct RouteLedgerAccountRulesIDDatasetQuery: RouteLedgerAccountRulesIDDestination {
    let client: Acme_Datasets_V1_DatasetQueryService.Client<MeshTransport>

    func write(_ rec: RouteLedgerAccountRulesIDRecord) async throws {
        _ = try await client.suggestDatasets(.with {
            $0.orderBy = rec.currencyCode
            $0.page.pageToken = rec.status
        })
    }
}

/// Sends records to acme.appointments.v1.ClinicSlotWorkflowService.
struct RouteLedgerAccountRulesIDClinicSlotWorkflow: RouteLedgerAccountRulesIDDestination {
    let client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client<MeshTransport>

    func write(_ rec: RouteLedgerAccountRulesIDRecord) async throws {
        _ = try await client.signalClinicSlotWorkflow(.with {
            $0.details.initiatedBy = rec.message
            $0.clinicSlot.title = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RouteLedgerAccountRulesIDLogOnly: RouteLedgerAccountRulesIDDestination {
    let logger = Logger(label: "acme.route-ledger-account-rules-id")

    func write(_ rec: RouteLedgerAccountRulesIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.ledger.v1.LedgerAccountValidationService/GetLedgerAccountRules and hands what it keeps to the sink of its kind.
enum RouteLedgerAccountRulesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Ledger_V1_LedgerAccountValidationService.Client(wrapping: mesh)
        let reply = try await origin.getLedgerAccountRules(.with { $0.ledgerAccountID = "current-route-ledger-account-rules-id" })
        let entry = RouteLedgerAccountRulesIDRecord(
            correlationID: reply.result.correlationID,
            message: reply.result.message,
            currencyCode: reply.ledgerAccount.currencyCode,
            status: reply.result.status
        )
        try await deliver("payment-calculation", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RouteLedgerAccountRulesIDRecord, _ mesh: MeshClient) async throws {
        var sink: any RouteLedgerAccountRulesIDDestination = RouteLedgerAccountRulesIDLogOnly()
        switch kind {
        case "payment-calculation":
            sink = RouteLedgerAccountRulesIDPaymentCalculation(client: Acme_Payments_V1_PaymentCalculationService.Client(wrapping: mesh))
        case "dataset-query":
            sink = RouteLedgerAccountRulesIDDatasetQuery(client: Acme_Datasets_V1_DatasetQueryService.Client(wrapping: mesh))
        case "clinic-slot-workflow":
            sink = RouteLedgerAccountRulesIDClinicSlotWorkflow(client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
