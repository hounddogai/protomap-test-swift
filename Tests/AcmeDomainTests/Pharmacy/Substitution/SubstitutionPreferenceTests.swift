@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newSubstitutionPreference("code-534", name: "name-146")
        #expect(item.status == Pharmacy.SubstitutionPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newSubstitutionPreference("code-534", name: "name-146")
        try item.moveTo(Pharmacy.SubstitutionPreferenceStatus.withdrawn)
        #expect(item.status == Pharmacy.SubstitutionPreferenceStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newSubstitutionPreference("code-534", name: "name-146")
        item.status = Pharmacy.SubstitutionPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionPreferenceStatus.proposed) }
    }
}
