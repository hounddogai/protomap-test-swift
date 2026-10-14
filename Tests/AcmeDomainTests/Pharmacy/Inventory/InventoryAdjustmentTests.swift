@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAdjustmentTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryAdjustment("code-74", label: "label-612")
        #expect(item.status == Pharmacy.InventoryAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newInventoryAdjustment("code-74", label: "label-612")
        try item.moveTo(Pharmacy.InventoryAdjustmentStatus.running)
        #expect(item.status == Pharmacy.InventoryAdjustmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryAdjustment("code-74", label: "label-612")
        item.status = Pharmacy.InventoryAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryAdjustmentStatus.new) }
    }
}
