@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSlotTests {
    @Test func startsInNew() throws {
        let item = Labs.newPanelSlot("code-720", label: "label-278")
        #expect(item.status == Labs.PanelSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newPanelSlot("code-720", label: "label-278")
        try item.moveTo(Labs.PanelSlotStatus.running)
        #expect(item.status == Labs.PanelSlotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPanelSlot("code-720", label: "label-278")
        item.status = Labs.PanelSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelSlotStatus.new) }
    }
}
