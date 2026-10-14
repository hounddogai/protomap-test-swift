import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyPatientHomeCatalogToken keeps of each SearchPatientHomeCatalog response.
struct CopyPatientHomeCatalogTokenRecord {
    var nextPageToken: String
    var status: String
    var message: String
    var correlationID: String
}

/// Where CopyPatientHomeCatalogToken hands each record.
protocol CopyPatientHomeCatalogTokenTarget {
    func deliver(_ rec: CopyPatientHomeCatalogTokenRecord) async throws
}

/// Hands records to acme.ledger.v1.LedgerAccountService.
struct CopyPatientHomeCatalogTokenLedgerAccount: CopyPatientHomeCatalogTokenTarget {
    let client: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>

    func deliver(_ rec: CopyPatientHomeCatalogTokenRecord) async throws {
        let request = Acme_Ledger_V1_ListLedgerAccountsRequest.with {
            $0.page.pageToken = rec.status
            $0.orderBy = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listLedgerAccounts(request)
        }
    }
}

/// Writes records to acme.telehealth.v1.TriageValidationService.
struct CopyPatientHomeCatalogTokenTriageValidation: CopyPatientHomeCatalogTokenTarget {
    let client: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>

    func deliver(_ rec: CopyPatientHomeCatalogTokenRecord) async throws {
        let request = Acme_Telehealth_V1_LintTriagesRequest.with {
            $0.triage.subject = rec.nextPageToken
            $0.triage.triageID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintTriages(request)
        }
    }
}

/// Writes records to acme.authorization.v1.AccessPolicyValidationService.
struct CopyPatientHomeCatalogTokenAccessPolicyValidation: CopyPatientHomeCatalogTokenTarget {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func deliver(_ rec: CopyPatientHomeCatalogTokenRecord) async throws {
        _ = try await client.lintAccessPolicies(.with {
            $0.accessPolicy.name = rec.message
            $0.accessPolicyID = rec.correlationID
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeGatewayService/SearchPatientHomeCatalog and hands what it keeps to the sink of its kind.
enum CopyPatientHomeCatalogToken {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)
        let reply = try await upstream.searchPatientHomeCatalog(.with { $0.orderBy = "default-copy-patient-home-catalog-token" })
        let row = CopyPatientHomeCatalogTokenRecord(
            nextPageToken: reply.pageInfo.nextPageToken,
            status: reply.result.status,
            message: reply.result.message,
            correlationID: reply.result.correlationID
        )
        try await act("access-policy-validation", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CopyPatientHomeCatalogTokenRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "ledger-account": { try await CopyPatientHomeCatalogTokenLedgerAccount(client: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: mesh)).deliver(rec) },
            "triage-validation": { try await CopyPatientHomeCatalogTokenTriageValidation(client: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: mesh)).deliver(rec) },
            "access-policy-validation": { try await CopyPatientHomeCatalogTokenAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)).deliver(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
