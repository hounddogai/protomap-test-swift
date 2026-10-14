@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelSlotTests {
    @Test func startsInIdle() throws {
        let item = Labs.newTieredPanelSlot("code-179", label: "label-5")
        #expect(item.status == Labs.TieredPanelSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newTieredPanelSlot("code-179", label: "label-5")
        try item.moveTo(Labs.TieredPanelSlotStatus.ready)
        #expect(item.status == Labs.TieredPanelSlotStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newTieredPanelSlot("code-179", label: "label-5")
        item.status = Labs.TieredPanelSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredPanelSlotStatus.idle) }
    }
}
