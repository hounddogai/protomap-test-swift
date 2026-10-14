@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyEstimateTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newWeightedFormularyEstimate("code-985", label: "label-113")
        #expect(item.status == Pharmacy.WeightedFormularyEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newWeightedFormularyEstimate("code-985", label: "label-113")
        try item.moveTo(Pharmacy.WeightedFormularyEstimateStatus.revoked)
        #expect(item.status == Pharmacy.WeightedFormularyEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newWeightedFormularyEstimate("code-985", label: "label-113")
        item.status = Pharmacy.WeightedFormularyEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedFormularyEstimateStatus.requested) }
    }
}
