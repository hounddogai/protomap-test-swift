import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffSearchIndexID keeps of each DeleteSearchIndex response.
struct HandOffSearchIndexIDRecord {
    var correlationID: String
    var message: String
}

/// Where HandOffSearchIndexID hands each record.
protocol HandOffSearchIndexIDSink {
    func push(_ rec: HandOffSearchIndexIDRecord) async throws
}

/// Hands records to acme.ledger.v1.LedgerAccountService.
struct HandOffSearchIndexIDLedgerAccount: HandOffSearchIndexIDSink {
    let client: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>

    func push(_ rec: HandOffSearchIndexIDRecord) async throws {
        _ = try await client.searchLedgerAccounts(.with {
            $0.filter.query = rec.correlationID
        })
    }
}

/// Passes records to acme.prescriptions.v1.MedicationLifecycleService.
struct HandOffSearchIndexIDMedicationLifecycle: HandOffSearchIndexIDSink {
    let client: Acme_Prescriptions_V1_MedicationLifecycleService.Client<MeshTransport>

    func push(_ rec: HandOffSearchIndexIDRecord) async throws {
        let request = Acme_Prescriptions_V1_GetMedicationLifecycleRequest.with {
            $0.medicationID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getMedicationLifecycle(request)
        }
    }
}

/// Reads acme.search.v1.SearchIndexService/DeleteSearchIndex and hands what it keeps to the sink of its kind.
enum HandOffSearchIndexID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Search_V1_SearchIndexService.Client(wrapping: mesh)
        let found = try await origin.deleteSearchIndex(.with { $0.etag = "main-hand-off-search-index-id" })
        let record = HandOffSearchIndexIDRecord(
            correlationID: found.result.correlationID,
            message: Kit.Text.normalize(found.result.message)
        )
        try await act("ledger-account", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: HandOffSearchIndexIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "ledger-account": { try await HandOffSearchIndexIDLedgerAccount(client: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: mesh)).push(rec) },
            "medication-lifecycle": { try await HandOffSearchIndexIDMedicationLifecycle(client: Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh)).push(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
