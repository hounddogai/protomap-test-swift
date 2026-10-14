@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Labs.newPanelMilestone("code-508", name: "name-463")
        #expect(item.status == Labs.PanelMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newPanelMilestone("code-508", name: "name-463")
        try item.moveTo(Labs.PanelMilestoneStatus.warming)
        #expect(item.status == Labs.PanelMilestoneStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newPanelMilestone("code-508", name: "name-463")
        item.status = Labs.PanelMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelMilestoneStatus.idle) }
    }
}
