@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionTierTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newLegacyInteractionTier("code-533", name: "name-491")
        #expect(item.status == Pharmacy.LegacyInteractionTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newLegacyInteractionTier("code-533", name: "name-491")
        try item.moveTo(Pharmacy.LegacyInteractionTierStatus.retired)
        #expect(item.status == Pharmacy.LegacyInteractionTierStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newLegacyInteractionTier("code-533", name: "name-491")
        item.status = Pharmacy.LegacyInteractionTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInteractionTierStatus.created) }
    }
}
