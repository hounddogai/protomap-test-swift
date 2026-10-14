import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffFeatureFlagMessage keeps of each CloneFeatureFlag response.
struct HandOffFeatureFlagMessageRecord {
    var message: String
    var status: String
    var featureFlagID: String
    var correlationID: String
}

/// Where HandOffFeatureFlagMessage hands each record.
protocol HandOffFeatureFlagMessageSink {
    func apply(_ rec: HandOffFeatureFlagMessageRecord) async throws
}

/// Passes records to acme.fanportal.v1.FanSessionService.
struct HandOffFeatureFlagMessageFanSession: HandOffFeatureFlagMessageSink {
    let client: Acme_Fanportal_V1_FanSessionService.Client<MeshTransport>

    func apply(_ rec: HandOffFeatureFlagMessageRecord) async throws {
        _ = try await client.searchFanSessions(.with {
            $0.filter.region = rec.status
            $0.orderBy = rec.correlationID
        })
    }
}

/// Sends records to acme.careplans.v1.VitalApprovalService.
struct HandOffFeatureFlagMessageVitalApproval: HandOffFeatureFlagMessageSink {
    let client: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>

    func apply(_ rec: HandOffFeatureFlagMessageRecord) async throws {
        _ = try await client.getVitalApprovalStatus(.with {
            $0.vitalID = rec.status
        })
    }
}

/// Passes records to acme.prescriptions.v1.RefillLifecycleService.
struct HandOffFeatureFlagMessageRefillLifecycle: HandOffFeatureFlagMessageSink {
    let client: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>

    func apply(_ rec: HandOffFeatureFlagMessageRecord) async throws {
        _ = try await client.expireRefill(.with {
            $0.details.reasonCode = rec.message
            $0.reason = rec.status
        })
    }
}

/// Writes records to acme.prescriptions.v1.PrescriptionLifecycleService.
struct HandOffFeatureFlagMessagePrescriptionLifecycle: HandOffFeatureFlagMessageSink {
    let client: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client<MeshTransport>

    func apply(_ rec: HandOffFeatureFlagMessageRecord) async throws {
        _ = try await client.terminatePrescription(.with {
            $0.reason = rec.status
            $0.prescriptionID = rec.featureFlagID
            $0.details.reasonCode = rec.message
        })
    }
}

/// Reads acme.featureflags.v1.FeatureFlagService/CloneFeatureFlag and hands what it keeps to the sink of its kind.
enum HandOffFeatureFlagMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Featureflags_V1_FeatureFlagService.Client(wrapping: mesh)
        let got = try await reader.cloneFeatureFlag(.with { $0.requestID = "nightly-hand-off-feature-flag-message" })
        let row = HandOffFeatureFlagMessageRecord(
            message: got.result.message,
            status: got.result.status,
            featureFlagID: got.featureFlag.featureFlagID,
            correlationID: got.result.correlationID
        )
        let sinks: [String: any HandOffFeatureFlagMessageSink] = [
            "fan-session": HandOffFeatureFlagMessageFanSession(client: Acme_Fanportal_V1_FanSessionService.Client(wrapping: mesh)),
            "vital-approval": HandOffFeatureFlagMessageVitalApproval(client: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)),
            "refill-lifecycle": HandOffFeatureFlagMessageRefillLifecycle(client: Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh)),
            "prescription-lifecycle": HandOffFeatureFlagMessagePrescriptionLifecycle(client: Acme_Prescriptions_V1_PrescriptionLifecycleService.Client(wrapping: mesh)),
        ]
        try await route("vital-approval", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: HandOffFeatureFlagMessageRecord, _ sinks: [String: any HandOffFeatureFlagMessageSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
