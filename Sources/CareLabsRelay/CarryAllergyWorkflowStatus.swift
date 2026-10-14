import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryAllergyWorkflowStatus keeps of each SignalAllergyWorkflow response.
struct CarryAllergyWorkflowStatusRecord {
    var status: String
    var source: String
    var allergyID: String
    var outcomeStatus: String
}

/// Where CarryAllergyWorkflowStatus hands each record.
protocol CarryAllergyWorkflowStatusDestination {
    func send(_ rec: CarryAllergyWorkflowStatusRecord) async throws
}

/// Hands records to acme.keymanagement.v1.CryptoKeyCalculationService.
struct CarryAllergyWorkflowStatusCryptoKeyCalculation: CarryAllergyWorkflowStatusDestination {
    let client: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client<MeshTransport>

    func send(_ rec: CarryAllergyWorkflowStatusRecord) async throws {
        _ = try await client.getCryptoKeyRates(.with {
            $0.cryptoKeyID = rec.allergyID
        })
    }
}

/// Sends records to acme.careplans.v1.CareGoalLifecycleService.
struct CarryAllergyWorkflowStatusCareGoalLifecycle: CarryAllergyWorkflowStatusDestination {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func send(_ rec: CarryAllergyWorkflowStatusRecord) async throws {
        let request = Acme_Careplans_V1_ExpireCareGoalRequest.with {
            $0.careGoalID = rec.source
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.expireCareGoal(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct CarryAllergyWorkflowStatusLogOnly: CarryAllergyWorkflowStatusDestination {
    let logger = Logger(label: "acme.carry-allergy-workflow-status")

    func send(_ rec: CarryAllergyWorkflowStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.patients.v1.AllergyWorkflowService/SignalAllergyWorkflow and hands what it keeps to the sink of its kind.
enum CarryAllergyWorkflowStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)
        let reply = try await upstream.signalAllergyWorkflow(.with { $0.allergyID = "current-carry-allergy-workflow-status" })
        let row = CarryAllergyWorkflowStatusRecord(
            status: Kit.Text.normalize(reply.result.status),
            source: reply.allergy.source,
            allergyID: reply.allergy.allergyID,
            outcomeStatus: reply.outcome.status
        )
        try await dispatch("care-goal-lifecycle", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: CarryAllergyWorkflowStatusRecord, _ mesh: MeshClient) async throws {
        var write: (CarryAllergyWorkflowStatusRecord) async throws -> Void = CarryAllergyWorkflowStatusLogOnly().send
        switch kind {
        case "crypto-key-calculation":
            write = CarryAllergyWorkflowStatusCryptoKeyCalculation(client: Acme_Keymanagement_V1_CryptoKeyCalculationService.Client(wrapping: mesh)).send
        case "care-goal-lifecycle":
            write = CarryAllergyWorkflowStatusCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)).send
        default:
            break
        }
        try await write(rec)
    }
}
