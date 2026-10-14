import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateDispatchOrderStatus keeps of each PeekDispatchOrder response.
struct PropagateDispatchOrderStatusRecord {
    var status: String
    var notes: String
    var number: String
}

/// Where PropagateDispatchOrderStatus hands each record.
protocol PropagateDispatchOrderStatusTarget {
    func deliver(_ rec: PropagateDispatchOrderStatusRecord) async throws
}

/// Sends records to acme.telehealth.v1.VideoVisitApprovalService.
struct PropagateDispatchOrderStatusVideoVisitApproval: PropagateDispatchOrderStatusTarget {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func deliver(_ rec: PropagateDispatchOrderStatusRecord) async throws {
        _ = try await client.getVideoVisitApprovalStatus(.with {
            $0.videoVisitID = rec.notes
        })
    }
}

/// Hands records to acme.boxoffice.v1.BoxOfficeSaleService.
struct PropagateDispatchOrderStatusBoxOfficeSale: PropagateDispatchOrderStatusTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleService.Client<MeshTransport>

    func deliver(_ rec: PropagateDispatchOrderStatusRecord) async throws {
        _ = try await client.deleteBoxOfficeSale(.with {
            $0.etag = rec.status
            $0.boxOfficeSaleID = rec.notes
            $0.reason = rec.number
        })
    }
}

/// Reads acme.dispatch.v1.DispatchOrderQueryService/PeekDispatchOrder and hands what it keeps to the sink of its kind.
enum PropagateDispatchOrderStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh)
        let got = try await reader.peekDispatchOrder(.with { $0.dispatchOrderID = "live-propagate-dispatch-order-status" })
        let rec = PropagateDispatchOrderStatusRecord(
            status: got.result.status,
            notes: got.dispatchOrder.notes,
            number: got.dispatchOrder.number
        )
        try await act("box-office-sale", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: PropagateDispatchOrderStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "video-visit-approval": { try await PropagateDispatchOrderStatusVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)).deliver(rec) },
            "box-office-sale": { try await PropagateDispatchOrderStatusBoxOfficeSale(client: Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: mesh)).deliver(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
