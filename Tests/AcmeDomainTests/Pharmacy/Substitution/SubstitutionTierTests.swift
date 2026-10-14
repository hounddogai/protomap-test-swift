@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionTierTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newSubstitutionTier("code-564", title: "title-522")
        #expect(item.status == Pharmacy.SubstitutionTierStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newSubstitutionTier("code-564", title: "title-522")
        try item.moveTo(Pharmacy.SubstitutionTierStatus.approved)
        #expect(item.status == Pharmacy.SubstitutionTierStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newSubstitutionTier("code-564", title: "title-522")
        item.status = Pharmacy.SubstitutionTierStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionTierStatus.proposed) }
    }
}
