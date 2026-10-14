@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryRollupTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newInventoryRollup("code-139", name: "name-472")
        #expect(item.status == Pharmacy.InventoryRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newInventoryRollup("code-139", name: "name-472")
        try item.moveTo(Pharmacy.InventoryRollupStatus.ready)
        #expect(item.status == Pharmacy.InventoryRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newInventoryRollup("code-139", name: "name-472")
        item.status = Pharmacy.InventoryRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryRollupStatus.idle) }
    }
}
