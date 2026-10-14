import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillSeatMapStatus keeps of each DeleteSeatMap response.
struct BackfillSeatMapStatusRecord {
    var status: String
    var correlationID: String
    var message: String
}

/// Where BackfillSeatMapStatus hands each record.
protocol BackfillSeatMapStatusWriter {
    func push(_ rec: BackfillSeatMapStatusRecord) async throws
}

/// Writes records to acme.audit.v1.AuditEventService.
struct BackfillSeatMapStatusAuditEvent: BackfillSeatMapStatusWriter {
    let client: Acme_Audit_V1_AuditEventService.Client<MeshTransport>

    func push(_ rec: BackfillSeatMapStatusRecord) async throws {
        _ = try await client.listAuditEvents(.with {
            $0.page.pageToken = rec.status
            $0.filter.region = rec.correlationID
            $0.filter.ownerID = rec.message
        })
    }
}

/// Hands records to acme.identity.v1.UserValidationService.
struct BackfillSeatMapStatusUserValidation: BackfillSeatMapStatusWriter {
    let client: Acme_Identity_V1_UserValidationService.Client<MeshTransport>

    func push(_ rec: BackfillSeatMapStatusRecord) async throws {
        let request = Acme_Identity_V1_ScoreUserRequest.with {
            $0.user.userID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreUser(request)
        }
    }
}

/// Sends records to acme.careplans.v1.CareGoalCalculationService.
struct BackfillSeatMapStatusCareGoalCalculation: BackfillSeatMapStatusWriter {
    let client: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>

    func push(_ rec: BackfillSeatMapStatusRecord) async throws {
        let request = Acme_Careplans_V1_CompareCareGoalOptionsRequest.with {
            $0.careGoal.careGoalID = rec.status
            $0.careGoalID = rec.correlationID
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareCareGoalOptions(request)
        }
    }
}

/// Reads acme.seating.v1.SeatMapService/DeleteSeatMap and hands what it keeps to the sink of its kind.
enum BackfillSeatMapStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Seating_V1_SeatMapService.Client(wrapping: mesh)
        let got = try await reader.deleteSeatMap(.with { $0.seatMapID = "nightly-backfill-seat-map-status" })
        let rec = BackfillSeatMapStatusRecord(
            status: got.result.status,
            correlationID: got.result.correlationID,
            message: got.result.message
        )
        try await act("user-validation", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: BackfillSeatMapStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "audit-event": { try await BackfillSeatMapStatusAuditEvent(client: Acme_Audit_V1_AuditEventService.Client(wrapping: mesh)).push(rec) },
            "user-validation": { try await BackfillSeatMapStatusUserValidation(client: Acme_Identity_V1_UserValidationService.Client(wrapping: mesh)).push(rec) },
            "care-goal-calculation": { try await BackfillSeatMapStatusCareGoalCalculation(client: Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)).push(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
