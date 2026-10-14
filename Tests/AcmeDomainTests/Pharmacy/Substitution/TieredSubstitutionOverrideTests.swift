@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredSubstitutionOverrideTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newTieredSubstitutionOverride("code-520", label: "label-61")
        #expect(item.status == Pharmacy.TieredSubstitutionOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newTieredSubstitutionOverride("code-520", label: "label-61")
        try item.moveTo(Pharmacy.TieredSubstitutionOverrideStatus.pending)
        #expect(item.status == Pharmacy.TieredSubstitutionOverrideStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newTieredSubstitutionOverride("code-520", label: "label-61")
        item.status = Pharmacy.TieredSubstitutionOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredSubstitutionOverrideStatus.draft) }
    }
}
