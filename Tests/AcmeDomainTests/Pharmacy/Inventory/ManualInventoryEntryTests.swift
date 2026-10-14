@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventoryEntryTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newManualInventoryEntry("code-157", name: "name-478")
        #expect(item.status == Pharmacy.ManualInventoryEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newManualInventoryEntry("code-157", name: "name-478")
        try item.moveTo(Pharmacy.ManualInventoryEntryStatus.running)
        #expect(item.status == Pharmacy.ManualInventoryEntryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newManualInventoryEntry("code-157", name: "name-478")
        item.status = Pharmacy.ManualInventoryEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualInventoryEntryStatus.new) }
    }
}
