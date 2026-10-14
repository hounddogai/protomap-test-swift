@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseMappingTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newWeightedDispenseMapping("code-167", label: "label-924")
        #expect(item.status == Pharmacy.WeightedDispenseMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newWeightedDispenseMapping("code-167", label: "label-924")
        try item.moveTo(Pharmacy.WeightedDispenseMappingStatus.published)
        #expect(item.status == Pharmacy.WeightedDispenseMappingStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newWeightedDispenseMapping("code-167", label: "label-924")
        item.status = Pharmacy.WeightedDispenseMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedDispenseMappingStatus.created) }
    }
}
