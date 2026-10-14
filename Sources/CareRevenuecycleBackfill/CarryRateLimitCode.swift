import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryRateLimitCode keeps of each CalculateRateLimit response.
struct CarryRateLimitCodeRecord {
    var currencyCode: String
    var rateLimitID: String
    var message: String
    var description: String
}

/// Where CarryRateLimitCode hands each record.
protocol CarryRateLimitCodeWriter {
    func write(_ rec: CarryRateLimitCodeRecord) async throws
}

/// Passes records to acme.careplans.v1.CareGoalLifecycleService.
struct CarryRateLimitCodeCareGoalLifecycle: CarryRateLimitCodeWriter {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func write(_ rec: CarryRateLimitCodeRecord) async throws {
        _ = try await client.renewCareGoal(.with {
            $0.details.reasonCode = rec.rateLimitID
        })
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteCalculationService.
struct CarryRateLimitCodeVisitNoteCalculation: CarryRateLimitCodeWriter {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func write(_ rec: CarryRateLimitCodeRecord) async throws {
        let request = Acme_Telehealth_V1_RecalculateVisitNotesRequest.with {
            $0.visitNote.visitNoteID = rec.description
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.recalculateVisitNotes(request)
        }
    }
}

/// Reads acme.ratelimiting.v1.RateLimitCalculationService/CalculateRateLimit and hands what it keeps to the sink of its kind.
enum CarryRateLimitCode {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)
        let response = try await origin.calculateRateLimit(.with { $0.rateLimitID = "default-carry-rate-limit-code" })
        let record = CarryRateLimitCodeRecord(
            currencyCode: Kit.Text.normalize(response.breakdown.currencyCode),
            rateLimitID: response.rateLimit.rateLimitID,
            message: response.result.message,
            description: response.rateLimit.description_p
        )
        let sinks: [String: any CarryRateLimitCodeWriter] = [
            "care-goal-lifecycle": CarryRateLimitCodeCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)),
            "visit-note-calculation": CarryRateLimitCodeVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "care-goal-lifecycle" {
                continue
            }
            try await sink.write(record)
        }
    }
}
