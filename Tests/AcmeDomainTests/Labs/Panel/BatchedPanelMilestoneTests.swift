@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedPanelMilestoneTests {
    @Test func startsInNew() throws {
        let item = Labs.newBatchedPanelMilestone("code-783", name: "name-647")
        #expect(item.status == Labs.BatchedPanelMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newBatchedPanelMilestone("code-783", name: "name-647")
        try item.moveTo(Labs.BatchedPanelMilestoneStatus.done)
        #expect(item.status == Labs.BatchedPanelMilestoneStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newBatchedPanelMilestone("code-783", name: "name-647")
        item.status = Labs.BatchedPanelMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedPanelMilestoneStatus.new) }
    }
}
