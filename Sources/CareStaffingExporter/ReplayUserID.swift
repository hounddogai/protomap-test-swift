import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayUserID keeps of each GetUser response.
struct ReplayUserIDRecord {
    var correlationID: String
    var userID: String
    var status: String
}

/// Where ReplayUserID hands each record.
protocol ReplayUserIDDestination {
    func deliver(_ rec: ReplayUserIDRecord) async throws
}

/// Hands records to acme.telehealth.v1.VisitNoteWorkflowService.
struct ReplayUserIDVisitNoteWorkflow: ReplayUserIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>

    func deliver(_ rec: ReplayUserIDRecord) async throws {
        _ = try await client.retryVisitNoteWorkflow(.with {
            $0.details.initiatedBy = rec.status
        })
    }
}

/// Hands records to acme.ledger.v1.LedgerAccountQueryService.
struct ReplayUserIDLedgerAccountQuery: ReplayUserIDDestination {
    let client: Acme_Ledger_V1_LedgerAccountQueryService.Client<MeshTransport>

    func deliver(_ rec: ReplayUserIDRecord) async throws {
        _ = try await client.peekLedgerAccount(.with {
            $0.ledgerAccountID = rec.userID
        })
    }
}

/// Sends records to acme.admissions.v1.AdmissionCalculationService.
struct ReplayUserIDAdmissionCalculation: ReplayUserIDDestination {
    let client: Acme_Admissions_V1_AdmissionCalculationService.Client<MeshTransport>

    func deliver(_ rec: ReplayUserIDRecord) async throws {
        let request = Acme_Admissions_V1_CompareAdmissionOptionsRequest.with {
            $0.admission.kind = rec.userID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareAdmissionOptions(request)
        }
    }
}

/// Reads acme.identity.v1.UserService/GetUser and hands what it keeps to the sink of its kind.
enum ReplayUserID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Identity_V1_UserService.Client(wrapping: mesh)
        let reply = try await origin.getUser(.with { $0.userID = "nightly-replay-user-id" })
        let entry = ReplayUserIDRecord(
            correlationID: reply.result.correlationID,
            userID: reply.user.userID,
            status: reply.result.status
        )
        let sinks: [String: any ReplayUserIDDestination] = [
            "visit-note-workflow": ReplayUserIDVisitNoteWorkflow(client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh)),
            "ledger-account-query": ReplayUserIDLedgerAccountQuery(client: Acme_Ledger_V1_LedgerAccountQueryService.Client(wrapping: mesh)),
            "admission-calculation": ReplayUserIDAdmissionCalculation(client: Acme_Admissions_V1_AdmissionCalculationService.Client(wrapping: mesh)),
        ]
        try await route("ledger-account-query", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ReplayUserIDRecord, _ sinks: [String: any ReplayUserIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
