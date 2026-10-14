import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffShowsID keeps of each SummarizeShows response.
struct HandOffShowsIDRecord {
    var reportID: String
    var status: String
    var correlationID: String
    var timezone: String
}

/// Where HandOffShowsID hands each record.
protocol HandOffShowsIDWriter {
    func send(_ rec: HandOffShowsIDRecord) async throws
}

/// Writes records to acme.ledger.v1.LedgerAccountValidationService.
struct HandOffShowsIDLedgerAccountValidation: HandOffShowsIDWriter {
    let client: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>

    func send(_ rec: HandOffShowsIDRecord) async throws {
        let request = Acme_Ledger_V1_PreviewLedgerAccountRequest.with {
            $0.ledgerAccount.ledgerAccountID = rec.timezone
            $0.ledgerAccountID = rec.correlationID
            $0.details.locale = rec.reportID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.previewLedgerAccount(request)
        }
    }
}

/// Sends records to acme.recommendations.v1.RecommendationSetService.
struct HandOffShowsIDRecommendationSet: HandOffShowsIDWriter {
    let client: Acme_Recommendations_V1_RecommendationSetService.Client<MeshTransport>

    func send(_ rec: HandOffShowsIDRecord) async throws {
        _ = try await client.getRecommendationSet(.with {
            $0.recommendationSetID = rec.timezone
        })
    }
}

/// Sends records to acme.telehealth.v1.TriageApprovalService.
struct HandOffShowsIDTriageApproval: HandOffShowsIDWriter {
    let client: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>

    func send(_ rec: HandOffShowsIDRecord) async throws {
        _ = try await client.approveTriage(.with {
            $0.reason = rec.status
            $0.triage.subject = rec.timezone
            $0.triageID = rec.correlationID
        })
    }
}

/// Reads acme.shows.v1.ShowQueryService/SummarizeShows and hands what it keeps to the sink of its kind.
enum HandOffShowsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh)
        let reply = try await upstream.summarizeShows(.with { $0.reason = "default-hand-off-shows-id" })
        let record = HandOffShowsIDRecord(
            reportID: reply.reportID,
            status: reply.result.status,
            correlationID: reply.result.correlationID,
            timezone: reply.period.timezone
        )
        try await act("triage-approval", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: HandOffShowsIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "ledger-account-validation": { try await HandOffShowsIDLedgerAccountValidation(client: Acme_Ledger_V1_LedgerAccountValidationService.Client(wrapping: mesh)).send(rec) },
            "recommendation-set": { try await HandOffShowsIDRecommendationSet(client: Acme_Recommendations_V1_RecommendationSetService.Client(wrapping: mesh)).send(rec) },
            "triage-approval": { try await HandOffShowsIDTriageApproval(client: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
