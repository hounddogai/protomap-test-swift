import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayVitalEligibilityID keeps of each CheckVitalEligibility response.
struct ReplayVitalEligibilityIDRecord {
    var correlationID: String
    var message: String
    var kind: String
}

/// Where ReplayVitalEligibilityID hands each record.
protocol ReplayVitalEligibilityIDWriter {
    func write(_ rec: ReplayVitalEligibilityIDRecord) async throws
}

/// Passes records to acme.careplans.v1.CareGoalValidationService.
struct ReplayVitalEligibilityIDCareGoalValidation: ReplayVitalEligibilityIDWriter {
    let client: Acme_Careplans_V1_CareGoalValidationService.Client<MeshTransport>

    func write(_ rec: ReplayVitalEligibilityIDRecord) async throws {
        _ = try await client.explainCareGoalDecision(.with {
            $0.details.locale = rec.correlationID
            $0.careGoalID = rec.message
        })
    }
}

/// Sends records to acme.keymanagement.v1.CryptoKeyCalculationService.
struct ReplayVitalEligibilityIDCryptoKeyCalculation: ReplayVitalEligibilityIDWriter {
    let client: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client<MeshTransport>

    func write(_ rec: ReplayVitalEligibilityIDRecord) async throws {
        let request = Acme_Keymanagement_V1_QuoteCryptoKeyRequest.with {
            $0.details.currencyCode = rec.kind
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quoteCryptoKey(request)
        }
    }
}

/// Passes records to acme.careplans.v1.VitalLifecycleService.
struct ReplayVitalEligibilityIDVitalLifecycle: ReplayVitalEligibilityIDWriter {
    let client: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>

    func write(_ rec: ReplayVitalEligibilityIDRecord) async throws {
        let request = Acme_Careplans_V1_ReinstateVitalRequest.with {
            $0.reason = rec.message
            $0.vitalID = rec.kind
            $0.details.reasonCode = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.reinstateVital(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayVitalEligibilityIDLogOnly: ReplayVitalEligibilityIDWriter {
    let logger = Logger(label: "acme.replay-vital-eligibility-id")

    func write(_ rec: ReplayVitalEligibilityIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.careplans.v1.VitalValidationService/CheckVitalEligibility and hands what it keeps to the sink of its kind.
enum ReplayVitalEligibilityID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)
        let response = try await origin.checkVitalEligibility(.with { $0.reason = "primary-replay-vital-eligibility-id" })
        let entry = ReplayVitalEligibilityIDRecord(
            correlationID: response.result.correlationID,
            message: Kit.Text.normalize(response.outcome.message),
            kind: response.vital.kind
        )
        try await dispatch("crypto-key-calculation", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: ReplayVitalEligibilityIDRecord, _ mesh: MeshClient) async throws {
        var write: (ReplayVitalEligibilityIDRecord) async throws -> Void = ReplayVitalEligibilityIDLogOnly().write
        switch kind {
        case "care-goal-validation":
            write = ReplayVitalEligibilityIDCareGoalValidation(client: Acme_Careplans_V1_CareGoalValidationService.Client(wrapping: mesh)).write
        case "crypto-key-calculation":
            write = ReplayVitalEligibilityIDCryptoKeyCalculation(client: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client(wrapping: mesh)).write
        case "vital-lifecycle":
            write = ReplayVitalEligibilityIDVitalLifecycle(client: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
