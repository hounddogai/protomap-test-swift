import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayTriageExpiryStatus keeps of each ScheduleTriageExpiry response.
struct RelayTriageExpiryStatusRecord {
    var status: String
    var referenceID: String
    var message: String
    var subject: String
}

/// Where RelayTriageExpiryStatus hands each record.
protocol RelayTriageExpiryStatusTarget {
    func send(_ rec: RelayTriageExpiryStatusRecord) async throws
}

/// Passes records to acme.fulfillment.v1.FulfillmentQueryService.
struct RelayTriageExpiryStatusFulfillmentQuery: RelayTriageExpiryStatusTarget {
    let client: Acme_Fulfillment_V1_FulfillmentQueryService.Client<MeshTransport>

    func send(_ rec: RelayTriageExpiryStatusRecord) async throws {
        _ = try await client.countFulfillments(.with {
            $0.page.pageToken = rec.status
            $0.filter.query = rec.referenceID
            $0.filter.ownerID = rec.message
        })
    }
}

/// Passes records to acme.ledger.v1.LedgerAccountValidationService.
struct RelayTriageExpiryStatusLedgerAccountValidation: RelayTriageExpiryStatusTarget {
    let client: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>

    func send(_ rec: RelayTriageExpiryStatusRecord) async throws {
        _ = try await client.validateLedgerAccount(.with {
            $0.ledgerAccount.ledgerAccountID = rec.subject
            $0.ledgerAccountID = rec.message
            $0.reason = rec.referenceID
        })
    }
}

/// Passes records to acme.prescriptions.v1.MedicationApprovalService.
struct RelayTriageExpiryStatusMedicationApproval: RelayTriageExpiryStatusTarget {
    let client: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>

    func send(_ rec: RelayTriageExpiryStatusRecord) async throws {
        let request = Acme_Prescriptions_V1_ListPendingMedicationsRequest.with {
            $0.filter.query = rec.referenceID
            $0.page.pageToken = rec.status
            $0.filter.ownerID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listPendingMedications(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayTriageExpiryStatusLogOnly: RelayTriageExpiryStatusTarget {
    let logger = Logger(label: "acme.relay-triage-expiry-status")

    func send(_ rec: RelayTriageExpiryStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.telehealth.v1.TriageLifecycleService/ScheduleTriageExpiry and hands what it keeps to the sink of its kind.
enum RelayTriageExpiryStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)
        let got = try await upstream.scheduleTriageExpiry(.with { $0.triageID = "nightly-relay-triage-expiry-status" })
        let entry = RelayTriageExpiryStatusRecord(
            status: Kit.Text.normalize(got.result.status),
            referenceID: Kit.Text.normalize(got.outcome.referenceID),
            message: got.outcome.message,
            subject: got.triage.subject
        )
        try await dispatch("ledger-account-validation", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RelayTriageExpiryStatusRecord, _ mesh: MeshClient) async throws {
        var write: (RelayTriageExpiryStatusRecord) async throws -> Void = RelayTriageExpiryStatusLogOnly().send
        switch kind {
        case "fulfillment-query":
            write = RelayTriageExpiryStatusFulfillmentQuery(client: Acme_Fulfillment_V1_FulfillmentQueryService.Client(wrapping: mesh)).send
        case "ledger-account-validation":
            write = RelayTriageExpiryStatusLedgerAccountValidation(client: Acme_Ledger_V1_LedgerAccountValidationService.Client(wrapping: mesh)).send
        case "medication-approval":
            write = RelayTriageExpiryStatusMedicationApproval(client: Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh)).send
        default:
            break
        }
        try await write(rec)
    }
}
