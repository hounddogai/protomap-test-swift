import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayLedgerAccountEligibilityCode keeps of each CheckLedgerAccountEligibility response.
struct ReplayLedgerAccountEligibilityCodeRecord {
    var currencyCode: String
    var ledgerAccountID: String
}

/// Where ReplayLedgerAccountEligibilityCode hands each record.
protocol ReplayLedgerAccountEligibilityCodeDestination {
    func push(_ rec: ReplayLedgerAccountEligibilityCodeRecord) async throws
}

/// Sends records to acme.patients.v1.AllergyApprovalService.
struct ReplayLedgerAccountEligibilityCodeAllergyApproval: ReplayLedgerAccountEligibilityCodeDestination {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func push(_ rec: ReplayLedgerAccountEligibilityCodeRecord) async throws {
        _ = try await client.rejectAllergy(.with {
            $0.allergyID = rec.currencyCode
            $0.details.comment = rec.ledgerAccountID
        })
    }
}

/// Writes records to acme.anomalies.v1.AnomalyQueryService.
struct ReplayLedgerAccountEligibilityCodeAnomalyQuery: ReplayLedgerAccountEligibilityCodeDestination {
    let client: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>

    func push(_ rec: ReplayLedgerAccountEligibilityCodeRecord) async throws {
        _ = try await client.lookupAnomaly(.with {
            $0.anomalyID = rec.ledgerAccountID
        })
    }
}

/// Sends records to acme.telehealth.v1.VisitNoteWorkflowService.
struct ReplayLedgerAccountEligibilityCodeVisitNoteWorkflow: ReplayLedgerAccountEligibilityCodeDestination {
    let client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>

    func push(_ rec: ReplayLedgerAccountEligibilityCodeRecord) async throws {
        _ = try await client.startVisitNoteWorkflow(.with {
            $0.visitNote.visitNoteID = rec.ledgerAccountID
        })
    }
}

/// Writes records to acme.patients.v1.AllergyLifecycleService.
struct ReplayLedgerAccountEligibilityCodeAllergyLifecycle: ReplayLedgerAccountEligibilityCodeDestination {
    let client: Acme_Patients_V1_AllergyLifecycleService.Client<MeshTransport>

    func push(_ rec: ReplayLedgerAccountEligibilityCodeRecord) async throws {
        _ = try await client.expireAllergy(.with {
            $0.reason = rec.currencyCode
            $0.details.reasonCode = rec.ledgerAccountID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayLedgerAccountEligibilityCodeLogOnly: ReplayLedgerAccountEligibilityCodeDestination {
    let logger = Logger(label: "acme.replay-ledger-account-eligibility-code")

    func push(_ rec: ReplayLedgerAccountEligibilityCodeRecord) async throws {
        logger.info("No sink for record", metadata: ["currencyCode": .string(rec.currencyCode)])
    }
}

/// Reads acme.ledger.v1.LedgerAccountValidationService/CheckLedgerAccountEligibility and hands what it keeps to the sink of its kind.
enum ReplayLedgerAccountEligibilityCode {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Ledger_V1_LedgerAccountValidationService.Client(wrapping: mesh)
        let got = try await reader.checkLedgerAccountEligibility(.with { $0.reason = "live-replay-ledger-account-eligibility-code" })
        let record = ReplayLedgerAccountEligibilityCodeRecord(
            currencyCode: got.ledgerAccount.currencyCode,
            ledgerAccountID: got.ledgerAccount.ledgerAccountID
        )
        try await deliver("visit-note-workflow", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayLedgerAccountEligibilityCodeRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayLedgerAccountEligibilityCodeDestination = ReplayLedgerAccountEligibilityCodeLogOnly()
        switch kind {
        case "allergy-approval":
            sink = ReplayLedgerAccountEligibilityCodeAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh))
        case "anomaly-query":
            sink = ReplayLedgerAccountEligibilityCodeAnomalyQuery(client: Acme_Anomalies_V1_AnomalyQueryService.Client(wrapping: mesh))
        case "visit-note-workflow":
            sink = ReplayLedgerAccountEligibilityCodeVisitNoteWorkflow(client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh))
        case "allergy-lifecycle":
            sink = ReplayLedgerAccountEligibilityCodeAllergyLifecycle(client: Acme_Patients_V1_AllergyLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
