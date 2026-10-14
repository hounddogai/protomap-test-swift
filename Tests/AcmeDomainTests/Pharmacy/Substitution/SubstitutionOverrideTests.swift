@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionOverrideTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newSubstitutionOverride("code-249", name: "name-636")
        #expect(item.status == Pharmacy.SubstitutionOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newSubstitutionOverride("code-249", name: "name-636")
        try item.moveTo(Pharmacy.SubstitutionOverrideStatus.active)
        #expect(item.status == Pharmacy.SubstitutionOverrideStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newSubstitutionOverride("code-249", name: "name-636")
        item.status = Pharmacy.SubstitutionOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionOverrideStatus.draft) }
    }
}
