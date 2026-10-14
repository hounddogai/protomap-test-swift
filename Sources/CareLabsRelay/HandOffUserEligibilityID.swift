import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffUserEligibilityID keeps of each CheckUserEligibility response.
struct HandOffUserEligibilityIDRecord {
    var userID: String
    var status: String
}

/// Where HandOffUserEligibilityID hands each record.
protocol HandOffUserEligibilityIDTarget {
    func send(_ rec: HandOffUserEligibilityIDRecord) async throws
}

/// Hands records to acme.careplans.v1.CareGoalLifecycleService.
struct HandOffUserEligibilityIDCareGoalLifecycle: HandOffUserEligibilityIDTarget {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func send(_ rec: HandOffUserEligibilityIDRecord) async throws {
        _ = try await client.suspendCareGoal(.with {
            $0.reason = rec.status
        })
    }
}

/// Writes records to acme.identity.v1.UserValidationService.
struct HandOffUserEligibilityIDUserValidation: HandOffUserEligibilityIDTarget {
    let client: Acme_Identity_V1_UserValidationService.Client<MeshTransport>

    func send(_ rec: HandOffUserEligibilityIDRecord) async throws {
        _ = try await client.scoreUser(.with {
            $0.reason = rec.userID
        })
    }
}

/// Writes records to acme.careplans.v1.CarePlanCalculationService.
struct HandOffUserEligibilityIDCarePlanCalculation: HandOffUserEligibilityIDTarget {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func send(_ rec: HandOffUserEligibilityIDRecord) async throws {
        _ = try await client.getCarePlanRates(.with {
            $0.carePlanID = rec.status
        })
    }
}

/// Reads acme.identity.v1.UserValidationService/CheckUserEligibility and hands what it keeps to the sink of its kind.
enum HandOffUserEligibilityID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Identity_V1_UserValidationService.Client(wrapping: mesh)
        let found = try await origin.checkUserEligibility(.with { $0.reason = "current-hand-off-user-eligibility-id" })
        let rec = HandOffUserEligibilityIDRecord(
            userID: found.user.userID,
            status: found.result.status
        )
        let sinks: [any HandOffUserEligibilityIDTarget] = [
            HandOffUserEligibilityIDCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)),
            HandOffUserEligibilityIDUserValidation(client: Acme_Identity_V1_UserValidationService.Client(wrapping: mesh)),
            HandOffUserEligibilityIDCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[2].send(rec)
    }
}
