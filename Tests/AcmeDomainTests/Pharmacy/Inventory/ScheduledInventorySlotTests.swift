@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventorySlotTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newScheduledInventorySlot("code-168", label: "label-800")
        #expect(item.status == Pharmacy.ScheduledInventorySlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newScheduledInventorySlot("code-168", label: "label-800")
        try item.moveTo(Pharmacy.ScheduledInventorySlotStatus.ready)
        #expect(item.status == Pharmacy.ScheduledInventorySlotStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newScheduledInventorySlot("code-168", label: "label-800")
        item.status = Pharmacy.ScheduledInventorySlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledInventorySlotStatus.idle) }
    }
}
