import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryCarePlanID keeps of each ExpireCarePlan response.
struct CarryCarePlanIDRecord {
    var correlationID: String
    var carePlanID: String
    var number: String
}

/// Sends records to acme.promotions.v1.PromotionCalculationService.
struct CarryCarePlanIDPromotionCalculation {
    let client: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>

    func deliver(_ rec: CarryCarePlanIDRecord) async throws {
        _ = try await client.simulatePromotion(.with {
            $0.promotion.description_p = rec.number
            $0.reason = rec.carePlanID
        })
    }
}

/// Reads acme.careplans.v1.CarePlanLifecycleService/ExpireCarePlan and hands what it keeps to acme.promotions.v1.PromotionCalculationService.
enum CarryCarePlanID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)
        let found = try await source.expireCarePlan(.with { $0.reason = "current-carry-care-plan-id" })
        let row = CarryCarePlanIDRecord(
            correlationID: found.result.correlationID,
            carePlanID: found.carePlan.carePlanID,
            number: Kit.Text.normalize(found.carePlan.number)
        )
        try await CarryCarePlanIDPromotionCalculation(client: Acme_Promotions_V1_PromotionCalculationService.Client(wrapping: mesh)).deliver(row)
    }
}
