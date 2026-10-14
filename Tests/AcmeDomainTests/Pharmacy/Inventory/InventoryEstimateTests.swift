@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryEstimateTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInventoryEstimate("code-877", name: "name-669")
        #expect(item.status == Pharmacy.InventoryEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newInventoryEstimate("code-877", name: "name-669")
        try item.moveTo(Pharmacy.InventoryEstimateStatus.active)
        #expect(item.status == Pharmacy.InventoryEstimateStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInventoryEstimate("code-877", name: "name-669")
        item.status = Pharmacy.InventoryEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryEstimateStatus.draft) }
    }
}
