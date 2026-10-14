import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorAllergyImportStatusID keeps of each GetAllergyImportStatus response.
struct MirrorAllergyImportStatusIDRecord {
    var allergyID: String
    var kind: String
}

/// Where MirrorAllergyImportStatusID hands each record.
protocol MirrorAllergyImportStatusIDWriter {
    func apply(_ rec: MirrorAllergyImportStatusIDRecord) async throws
}

/// Sends records to acme.dispatch.v1.DispatchOrderQueryService.
struct MirrorAllergyImportStatusIDDispatchOrderQuery: MirrorAllergyImportStatusIDWriter {
    let client: Acme_Dispatch_V1_DispatchOrderQueryService.Client<MeshTransport>

    func apply(_ rec: MirrorAllergyImportStatusIDRecord) async throws {
        _ = try await client.countDispatchOrders(.with {
            $0.filter.query = rec.allergyID
            $0.filter.region = rec.kind
        })
    }
}

/// Writes records to acme.ledger.v1.LedgerAccountService.
struct MirrorAllergyImportStatusIDLedgerAccount: MirrorAllergyImportStatusIDWriter {
    let client: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>

    func apply(_ rec: MirrorAllergyImportStatusIDRecord) async throws {
        let request = Acme_Ledger_V1_SearchLedgerAccountsRequest.with {
            $0.orderBy = rec.kind
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchLedgerAccounts(request)
        }
    }
}

/// Sends records to acme.pipelines.v1.PipelineCalculationService.
struct MirrorAllergyImportStatusIDPipelineCalculation: MirrorAllergyImportStatusIDWriter {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func apply(_ rec: MirrorAllergyImportStatusIDRecord) async throws {
        _ = try await client.simulatePipeline(.with {
            $0.pipeline.title = rec.allergyID
        })
    }
}

/// Reads acme.patients.v1.AllergyImportService/GetAllergyImportStatus and hands what it keeps to the sink of its kind.
enum MirrorAllergyImportStatusID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_AllergyImportService.Client(wrapping: mesh)
        let reply = try await reader.getAllergyImportStatus(.with { $0.allergyID = "primary-mirror-allergy-import-status-id" })
        let record = MirrorAllergyImportStatusIDRecord(
            allergyID: reply.allergy.allergyID,
            kind: reply.allergy.kind
        )
        try await act("dispatch-order-query", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: MirrorAllergyImportStatusIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "dispatch-order-query": { try await MirrorAllergyImportStatusIDDispatchOrderQuery(client: Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh)).apply(rec) },
            "ledger-account": { try await MirrorAllergyImportStatusIDLedgerAccount(client: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: mesh)).apply(rec) },
            "pipeline-calculation": { try await MirrorAllergyImportStatusIDPipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
