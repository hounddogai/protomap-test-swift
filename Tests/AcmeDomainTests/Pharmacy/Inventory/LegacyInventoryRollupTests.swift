@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryRollupTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newLegacyInventoryRollup("code-352", label: "label-163")
        #expect(item.status == Pharmacy.LegacyInventoryRollupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newLegacyInventoryRollup("code-352", label: "label-163")
        try item.moveTo(Pharmacy.LegacyInventoryRollupStatus.rejected)
        #expect(item.status == Pharmacy.LegacyInventoryRollupStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newLegacyInventoryRollup("code-352", label: "label-163")
        item.status = Pharmacy.LegacyInventoryRollupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInventoryRollupStatus.proposed) }
    }
}
