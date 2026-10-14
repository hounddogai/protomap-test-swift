import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleProviderID keeps of each SubmitProvider response.
struct SettleProviderIDRecord {
    var providerID: String
    var message: String
    var status: String
}

/// Where SettleProviderID hands each record.
protocol SettleProviderIDTarget {
    func deliver(_ rec: SettleProviderIDRecord) async throws
}

/// Hands records to acme.broadcasts.v1.BroadcastQueryService.
struct SettleProviderIDBroadcastQuery: SettleProviderIDTarget {
    let client: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>

    func deliver(_ rec: SettleProviderIDRecord) async throws {
        _ = try await client.peekBroadcast(.with {
            $0.broadcastID = rec.message
        })
    }
}

/// Hands records to acme.telehealth.v1.VideoVisitApprovalService.
struct SettleProviderIDVideoVisitApproval: SettleProviderIDTarget {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func deliver(_ rec: SettleProviderIDRecord) async throws {
        let request = Acme_Telehealth_V1_ListPendingVideoVisitsRequest.with {
            $0.filter.region = rec.providerID
            $0.filter.query = rec.message
            $0.filter.ownerID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listPendingVideoVisits(request)
        }
    }
}

/// Reads acme.appointments.v1.ProviderApprovalService/SubmitProvider and hands what it keeps to the sink of its kind.
enum SettleProviderID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)
        let response = try await source.submitProvider(.with { $0.providerID = "current-settle-provider-id" })
        let entry = SettleProviderIDRecord(
            providerID: response.provider.providerID,
            message: response.outcome.message,
            status: response.result.status
        )
        try await act("broadcast-query", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: SettleProviderIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "broadcast-query": { try await SettleProviderIDBroadcastQuery(client: Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: mesh)).deliver(rec) },
            "video-visit-approval": { try await SettleProviderIDVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)).deliver(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
