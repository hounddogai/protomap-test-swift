@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionTierTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newLenientSubstitutionTier("code-257", title: "title-370")
        #expect(item.status == Pharmacy.LenientSubstitutionTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newLenientSubstitutionTier("code-257", title: "title-370")
        try item.moveTo(Pharmacy.LenientSubstitutionTierStatus.pending)
        #expect(item.status == Pharmacy.LenientSubstitutionTierStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newLenientSubstitutionTier("code-257", title: "title-370")
        item.status = Pharmacy.LenientSubstitutionTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientSubstitutionTierStatus.draft) }
    }
}
