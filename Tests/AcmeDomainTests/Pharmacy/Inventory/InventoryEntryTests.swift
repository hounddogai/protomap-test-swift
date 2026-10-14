@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryEntryTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryEntry("code-220", label: "label-665")
        #expect(item.status == Pharmacy.InventoryEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newInventoryEntry("code-220", label: "label-665")
        try item.moveTo(Pharmacy.InventoryEntryStatus.done)
        #expect(item.status == Pharmacy.InventoryEntryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryEntry("code-220", label: "label-665")
        item.status = Pharmacy.InventoryEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryEntryStatus.new) }
    }
}
