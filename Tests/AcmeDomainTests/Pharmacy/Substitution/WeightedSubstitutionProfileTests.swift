@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionProfileTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newWeightedSubstitutionProfile("code-126", name: "name-264")
        #expect(item.status == Pharmacy.WeightedSubstitutionProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newWeightedSubstitutionProfile("code-126", name: "name-264")
        try item.moveTo(Pharmacy.WeightedSubstitutionProfileStatus.active)
        #expect(item.status == Pharmacy.WeightedSubstitutionProfileStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newWeightedSubstitutionProfile("code-126", name: "name-264")
        item.status = Pharmacy.WeightedSubstitutionProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedSubstitutionProfileStatus.draft) }
    }
}
