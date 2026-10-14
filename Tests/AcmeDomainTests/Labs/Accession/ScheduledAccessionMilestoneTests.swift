@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Labs.newScheduledAccessionMilestone("code-527", label: "label-358")
        #expect(item.status == Labs.ScheduledAccessionMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newScheduledAccessionMilestone("code-527", label: "label-358")
        try item.moveTo(Labs.ScheduledAccessionMilestoneStatus.withdrawn)
        #expect(item.status == Labs.ScheduledAccessionMilestoneStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newScheduledAccessionMilestone("code-527", label: "label-358")
        item.status = Labs.ScheduledAccessionMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledAccessionMilestoneStatus.proposed) }
    }
}
