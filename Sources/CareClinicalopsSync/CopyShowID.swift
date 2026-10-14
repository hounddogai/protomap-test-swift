import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyShowID keeps of each PeekShow response.
struct CopyShowIDRecord {
    var correlationID: String
    var message: String
}

/// Where CopyShowID hands each record.
protocol CopyShowIDTarget {
    func push(_ rec: CopyShowIDRecord) async throws
}

/// Sends records to acme.authorization.v1.AccessPolicyValidationService.
struct CopyShowIDAccessPolicyValidation: CopyShowIDTarget {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func push(_ rec: CopyShowIDRecord) async throws {
        let request = Acme_Authorization_V1_NormalizeAccessPolicyRequest.with {
            $0.accessPolicyID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.normalizeAccessPolicy(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.RefillLifecycleService.
struct CopyShowIDRefillLifecycle: CopyShowIDTarget {
    let client: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>

    func push(_ rec: CopyShowIDRecord) async throws {
        _ = try await client.scheduleRefillExpiry(.with {
            $0.refillID = rec.message
            $0.details.initiatedBy = rec.correlationID
        })
    }
}

/// Hands records to acme.accounting.v1.ChartOfAccountsService.
struct CopyShowIDChartOfAccounts: CopyShowIDTarget {
    let client: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>

    func push(_ rec: CopyShowIDRecord) async throws {
        _ = try await client.updateChartOfAccounts(.with {
            $0.chartOfAccounts.name = rec.correlationID
            $0.chartOfAccounts.parentID = rec.message
        })
    }
}

/// Reads acme.shows.v1.ShowQueryService/PeekShow and hands what it keeps to the sink of its kind.
enum CopyShowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh)
        let reply = try await upstream.peekShow(.with { $0.showID = "default-copy-show-id" })
        let rec = CopyShowIDRecord(
            correlationID: reply.result.correlationID,
            message: Kit.Text.normalize(reply.result.message)
        )
        let sinks: [String: any CopyShowIDTarget] = [
            "access-policy-validation": CopyShowIDAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)),
            "refill-lifecycle": CopyShowIDRefillLifecycle(client: Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh)),
            "chart-of-accounts": CopyShowIDChartOfAccounts(client: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["COPY_SHOW_ID_TARGET"] ?? ""] else {
            return
        }
        try await sink.push(rec)
    }
}
