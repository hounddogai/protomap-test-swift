@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryOverrideTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newInventoryOverride("code-588", title: "title-790")
        #expect(item.status == Pharmacy.InventoryOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newInventoryOverride("code-588", title: "title-790")
        try item.moveTo(Pharmacy.InventoryOverrideStatus.ready)
        #expect(item.status == Pharmacy.InventoryOverrideStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newInventoryOverride("code-588", title: "title-790")
        item.status = Pharmacy.InventoryOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryOverrideStatus.idle) }
    }
}
