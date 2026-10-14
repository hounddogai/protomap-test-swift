@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Labs.newLegacyAccessionMilestone("code-982", label: "label-759")
        #expect(item.status == Labs.LegacyAccessionMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newLegacyAccessionMilestone("code-982", label: "label-759")
        try item.moveTo(Labs.LegacyAccessionMilestoneStatus.warming)
        #expect(item.status == Labs.LegacyAccessionMilestoneStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newLegacyAccessionMilestone("code-982", label: "label-759")
        item.status = Labs.LegacyAccessionMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyAccessionMilestoneStatus.idle) }
    }
}
