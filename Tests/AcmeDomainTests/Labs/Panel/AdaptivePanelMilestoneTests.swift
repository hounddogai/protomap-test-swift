@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAdaptivePanelMilestone("code-401", name: "name-855")
        #expect(item.status == Labs.AdaptivePanelMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newAdaptivePanelMilestone("code-401", name: "name-855")
        try item.moveTo(Labs.AdaptivePanelMilestoneStatus.warming)
        #expect(item.status == Labs.AdaptivePanelMilestoneStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAdaptivePanelMilestone("code-401", name: "name-855")
        item.status = Labs.AdaptivePanelMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptivePanelMilestoneStatus.idle) }
    }
}
