@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveReferenceRangeMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAdaptiveReferenceRangeMilestone("code-507", title: "title-932")
        #expect(item.status == Labs.AdaptiveReferenceRangeMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newAdaptiveReferenceRangeMilestone("code-507", title: "title-932")
        try item.moveTo(Labs.AdaptiveReferenceRangeMilestoneStatus.approved)
        #expect(item.status == Labs.AdaptiveReferenceRangeMilestoneStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAdaptiveReferenceRangeMilestone("code-507", title: "title-932")
        item.status = Labs.AdaptiveReferenceRangeMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveReferenceRangeMilestoneStatus.proposed) }
    }
}
