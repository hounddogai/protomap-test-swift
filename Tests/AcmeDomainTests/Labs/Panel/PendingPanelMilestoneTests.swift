@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingPanelMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Labs.newPendingPanelMilestone("code-879", name: "name-483")
        #expect(item.status == Labs.PendingPanelMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newPendingPanelMilestone("code-879", name: "name-483")
        try item.moveTo(Labs.PendingPanelMilestoneStatus.validated)
        #expect(item.status == Labs.PendingPanelMilestoneStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newPendingPanelMilestone("code-879", name: "name-483")
        item.status = Labs.PendingPanelMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingPanelMilestoneStatus.created) }
    }
}
