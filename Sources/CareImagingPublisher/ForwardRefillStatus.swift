import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardRefillStatus keeps of each ScoreRefill response.
struct ForwardRefillStatusRecord {
    var status: String
    var refillID: String
    var currencyCode: String
}

/// Where ForwardRefillStatus hands each record.
protocol ForwardRefillStatusWriter {
    func forward(_ rec: ForwardRefillStatusRecord) async throws
}

/// Writes records to acme.careplans.v1.VitalCalculationService.
struct ForwardRefillStatusVitalCalculation: ForwardRefillStatusWriter {
    let client: Acme_Careplans_V1_VitalCalculationService.Client<MeshTransport>

    func forward(_ rec: ForwardRefillStatusRecord) async throws {
        _ = try await client.estimateVital(.with {
            $0.vital.correlationID = rec.status
            $0.vitalID = rec.currencyCode
            $0.details.currencyCode = rec.refillID
        })
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteLifecycleService.
struct ForwardRefillStatusVisitNoteLifecycle: ForwardRefillStatusWriter {
    let client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>

    func forward(_ rec: ForwardRefillStatusRecord) async throws {
        _ = try await client.expireVisitNote(.with {
            $0.reason = rec.currencyCode
        })
    }
}

/// Sends records to acme.fanportal.v1.FanSessionService.
struct ForwardRefillStatusFanSession: ForwardRefillStatusWriter {
    let client: Acme_Fanportal_V1_FanSessionService.Client<MeshTransport>

    func forward(_ rec: ForwardRefillStatusRecord) async throws {
        _ = try await client.searchFanSessions(.with {
            $0.filter.region = rec.status
        })
    }
}

/// Reads acme.prescriptions.v1.RefillValidationService/ScoreRefill and hands what it keeps to the sink of its kind.
enum ForwardRefillStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Prescriptions_V1_RefillValidationService.Client(wrapping: mesh)
        let reply = try await source.scoreRefill(.with { $0.refillID = "current-forward-refill-status" })
        let entry = ForwardRefillStatusRecord(
            status: reply.result.status,
            refillID: reply.refill.refillID,
            currencyCode: reply.breakdown.currencyCode
        )
        try await act("visit-note-lifecycle", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: ForwardRefillStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "vital-calculation": { try await ForwardRefillStatusVitalCalculation(client: Acme_Careplans_V1_VitalCalculationService.Client(wrapping: mesh)).forward(rec) },
            "visit-note-lifecycle": { try await ForwardRefillStatusVisitNoteLifecycle(client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)).forward(rec) },
            "fan-session": { try await ForwardRefillStatusFanSession(client: Acme_Fanportal_V1_FanSessionService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
