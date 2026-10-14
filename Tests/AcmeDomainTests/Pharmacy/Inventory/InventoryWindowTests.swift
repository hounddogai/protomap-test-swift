@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryWindowTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryWindow("code-519", title: "title-485")
        #expect(item.status == Pharmacy.InventoryWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newInventoryWindow("code-519", title: "title-485")
        try item.moveTo(Pharmacy.InventoryWindowStatus.running)
        #expect(item.status == Pharmacy.InventoryWindowStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryWindow("code-519", title: "title-485")
        item.status = Pharmacy.InventoryWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryWindowStatus.new) }
    }
}
