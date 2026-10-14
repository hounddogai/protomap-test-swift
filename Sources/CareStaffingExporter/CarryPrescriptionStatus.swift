import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryPrescriptionStatus keeps of each RenewPrescription response.
struct CarryPrescriptionStatusRecord {
    var status: String
    var prescriptionID: String
    var correlationID: String
}

/// Where CarryPrescriptionStatus hands each record.
protocol CarryPrescriptionStatusDestination {
    func deliver(_ rec: CarryPrescriptionStatusRecord) async throws
}

/// Sends records to acme.concessions.v1.ConcessionStandService.
struct CarryPrescriptionStatusConcessionStand: CarryPrescriptionStatusDestination {
    let client: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>

    func deliver(_ rec: CarryPrescriptionStatusRecord) async throws {
        let request = Acme_Concessions_V1_SearchConcessionStandsRequest.with {
            $0.filter.query = rec.prescriptionID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchConcessionStands(request)
        }
    }
}

/// Writes records to acme.careplans.v1.CareGoalCalculationService.
struct CarryPrescriptionStatusCareGoalCalculation: CarryPrescriptionStatusDestination {
    let client: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>

    func deliver(_ rec: CarryPrescriptionStatusRecord) async throws {
        _ = try await client.quoteCareGoal(.with {
            $0.reason = rec.prescriptionID
            $0.careGoalID = rec.status
        })
    }
}

/// Sends records to acme.authorization.v1.AccessPolicyValidationService.
struct CarryPrescriptionStatusAccessPolicyValidation: CarryPrescriptionStatusDestination {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func deliver(_ rec: CarryPrescriptionStatusRecord) async throws {
        _ = try await client.explainAccessPolicyDecision(.with {
            $0.accessPolicy.accessPolicyID = rec.correlationID
        })
    }
}

/// Hands records to acme.careplans.v1.CareGoalApprovalService.
struct CarryPrescriptionStatusCareGoalApproval: CarryPrescriptionStatusDestination {
    let client: Acme_Careplans_V1_CareGoalApprovalService.Client<MeshTransport>

    func deliver(_ rec: CarryPrescriptionStatusRecord) async throws {
        let request = Acme_Careplans_V1_DelegateCareGoalApprovalRequest.with {
            $0.careGoalID = rec.prescriptionID
            $0.careGoal.subject = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.delegateCareGoalApproval(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionLifecycleService/RenewPrescription and hands what it keeps to the sink of its kind.
enum CarryPrescriptionStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_PrescriptionLifecycleService.Client(wrapping: mesh)
        let got = try await upstream.renewPrescription(.with { $0.reason = "nightly-carry-prescription-status" })
        let row = CarryPrescriptionStatusRecord(
            status: got.result.status,
            prescriptionID: got.prescription.prescriptionID,
            correlationID: got.result.correlationID
        )
        let sinks: [String: any CarryPrescriptionStatusDestination] = [
            "concession-stand": CarryPrescriptionStatusConcessionStand(client: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)),
            "care-goal-calculation": CarryPrescriptionStatusCareGoalCalculation(client: Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)),
            "access-policy-validation": CarryPrescriptionStatusAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)),
            "care-goal-approval": CarryPrescriptionStatusCareGoalApproval(client: Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: mesh)),
        ]
        try await route("care-goal-calculation", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: CarryPrescriptionStatusRecord, _ sinks: [String: any CarryPrescriptionStatusDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
