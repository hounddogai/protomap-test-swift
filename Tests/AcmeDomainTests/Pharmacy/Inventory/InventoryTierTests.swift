@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryTierTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInventoryTier("code-231", label: "label-668")
        #expect(item.status == Pharmacy.InventoryTierStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newInventoryTier("code-231", label: "label-668")
        try item.moveTo(Pharmacy.InventoryTierStatus.rejected)
        #expect(item.status == Pharmacy.InventoryTierStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInventoryTier("code-231", label: "label-668")
        item.status = Pharmacy.InventoryTierStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryTierStatus.proposed) }
    }
}
