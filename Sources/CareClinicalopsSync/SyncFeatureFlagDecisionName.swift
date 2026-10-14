import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncFeatureFlagDecisionName keeps of each ExplainFeatureFlagDecision response.
struct SyncFeatureFlagDecisionNameRecord {
    var name: String
    var message: String
    var status: String
}

/// Where SyncFeatureFlagDecisionName hands each record.
protocol SyncFeatureFlagDecisionNameDestination {
    func apply(_ rec: SyncFeatureFlagDecisionNameRecord) async throws
}

/// Hands records to acme.telematics.v1.TelemetryReadingQueryService.
struct SyncFeatureFlagDecisionNameTelemetryReadingQuery: SyncFeatureFlagDecisionNameDestination {
    let client: Acme_Telematics_V1_TelemetryReadingQueryService.Client<MeshTransport>

    func apply(_ rec: SyncFeatureFlagDecisionNameRecord) async throws {
        _ = try await client.peekTelemetryReading(.with {
            $0.telemetryReadingID = rec.message
        })
    }
}

/// Hands records to acme.careplans.v1.CareGoalLifecycleService.
struct SyncFeatureFlagDecisionNameCareGoalLifecycle: SyncFeatureFlagDecisionNameDestination {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func apply(_ rec: SyncFeatureFlagDecisionNameRecord) async throws {
        let request = Acme_Careplans_V1_GetCareGoalLifecycleRequest.with {
            $0.careGoalID = rec.name
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getCareGoalLifecycle(request)
        }
    }
}

/// Sends records to acme.prescriptions.v1.MedicationLifecycleService.
struct SyncFeatureFlagDecisionNameMedicationLifecycle: SyncFeatureFlagDecisionNameDestination {
    let client: Acme_Prescriptions_V1_MedicationLifecycleService.Client<MeshTransport>

    func apply(_ rec: SyncFeatureFlagDecisionNameRecord) async throws {
        _ = try await client.getMedicationLifecycle(.with {
            $0.medicationID = rec.message
        })
    }
}

/// Reads acme.featureflags.v1.FeatureFlagValidationService/ExplainFeatureFlagDecision and hands what it keeps to the sink of its kind.
enum SyncFeatureFlagDecisionName {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh)
        let found = try await origin.explainFeatureFlagDecision(.with { $0.featureFlagID = "main-sync-feature-flag-decision-name" })
        let record = SyncFeatureFlagDecisionNameRecord(
            name: found.featureFlag.name,
            message: found.result.message,
            status: Kit.Text.normalize(found.outcome.status)
        )
        let sinks: [String: any SyncFeatureFlagDecisionNameDestination] = [
            "telemetry-reading-query": SyncFeatureFlagDecisionNameTelemetryReadingQuery(client: Acme_Telematics_V1_TelemetryReadingQueryService.Client(wrapping: mesh)),
            "care-goal-lifecycle": SyncFeatureFlagDecisionNameCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)),
            "medication-lifecycle": SyncFeatureFlagDecisionNameMedicationLifecycle(client: Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh)),
        ]
        try await route("telemetry-reading-query", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: SyncFeatureFlagDecisionNameRecord, _ sinks: [String: any SyncFeatureFlagDecisionNameDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
