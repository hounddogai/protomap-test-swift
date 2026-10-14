@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryClaimTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryClaim("code-670", name: "name-33")
        #expect(item.status == Pharmacy.InventoryClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Pharmacy.newInventoryClaim("code-670", name: "name-33")
        try item.moveTo(Pharmacy.InventoryClaimStatus.failed)
        #expect(item.status == Pharmacy.InventoryClaimStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryClaim("code-670", name: "name-33")
        item.status = Pharmacy.InventoryClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryClaimStatus.new) }
    }
}
