@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionTierTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPrimarySubstitutionTier("code-420", label: "label-366")
        #expect(item.status == Pharmacy.PrimarySubstitutionTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newPrimarySubstitutionTier("code-420", label: "label-366")
        try item.moveTo(Pharmacy.PrimarySubstitutionTierStatus.retired)
        #expect(item.status == Pharmacy.PrimarySubstitutionTierStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPrimarySubstitutionTier("code-420", label: "label-366")
        item.status = Pharmacy.PrimarySubstitutionTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimarySubstitutionTierStatus.created) }
    }
}
