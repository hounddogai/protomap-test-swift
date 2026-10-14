import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorLedgerAccountCode keeps of each PeekLedgerAccount response.
struct MirrorLedgerAccountCodeRecord {
    var currencyCode: String
    var correlationID: String
    var ledgerAccountID: String
}

/// Where MirrorLedgerAccountCode hands each record.
protocol MirrorLedgerAccountCodeSink {
    func deliver(_ rec: MirrorLedgerAccountCodeRecord) async throws
}

/// Passes records to acme.accounting.v1.ChartOfAccountsService.
struct MirrorLedgerAccountCodeChartOfAccounts: MirrorLedgerAccountCodeSink {
    let client: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>

    func deliver(_ rec: MirrorLedgerAccountCodeRecord) async throws {
        let request = Acme_Accounting_V1_DeleteChartOfAccountsRequest.with {
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteChartOfAccounts(request)
        }
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteApprovalService.
struct MirrorLedgerAccountCodeVisitNoteApproval: MirrorLedgerAccountCodeSink {
    let client: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>

    func deliver(_ rec: MirrorLedgerAccountCodeRecord) async throws {
        _ = try await client.rejectVisitNote(.with {
            $0.visitNote.notes = rec.ledgerAccountID
            $0.reason = rec.correlationID
        })
    }
}

/// Hands records to acme.prescriptions.v1.PrescriptionValidationService.
struct MirrorLedgerAccountCodePrescriptionValidation: MirrorLedgerAccountCodeSink {
    let client: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>

    func deliver(_ rec: MirrorLedgerAccountCodeRecord) async throws {
        _ = try await client.scorePrescription(.with {
            $0.prescription.prescriptionID = rec.correlationID
            $0.details.currencyCode = rec.currencyCode
            $0.prescription.notes = rec.ledgerAccountID
        })
    }
}

/// Reads acme.ledger.v1.LedgerAccountQueryService/PeekLedgerAccount and hands what it keeps to the sink of its kind.
enum MirrorLedgerAccountCode {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: mesh)
        let got = try await source.peekLedgerAccount(.with { $0.ledgerAccountID = "nightly-mirror-ledger-account-code" })
        let rec = MirrorLedgerAccountCodeRecord(
            currencyCode: got.ledgerAccount.currencyCode,
            correlationID: got.result.correlationID,
            ledgerAccountID: Kit.Text.normalize(got.ledgerAccount.ledgerAccountID)
        )
        let sinks: [String: any MirrorLedgerAccountCodeSink] = [
            "chart-of-accounts": MirrorLedgerAccountCodeChartOfAccounts(client: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh)),
            "visit-note-approval": MirrorLedgerAccountCodeVisitNoteApproval(client: Acme_Telehealth_V1_VisitNoteApprovalService.Client(wrapping: mesh)),
            "prescription-validation": MirrorLedgerAccountCodePrescriptionValidation(client: Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh)),
        ]
        try await route("chart-of-accounts", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: MirrorLedgerAccountCodeRecord, _ sinks: [String: any MirrorLedgerAccountCodeSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
