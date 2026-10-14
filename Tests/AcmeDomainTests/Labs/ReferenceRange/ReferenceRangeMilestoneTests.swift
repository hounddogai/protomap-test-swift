@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Labs.newReferenceRangeMilestone("code-339", label: "label-479")
        #expect(item.status == Labs.ReferenceRangeMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newReferenceRangeMilestone("code-339", label: "label-479")
        try item.moveTo(Labs.ReferenceRangeMilestoneStatus.published)
        #expect(item.status == Labs.ReferenceRangeMilestoneStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newReferenceRangeMilestone("code-339", label: "label-479")
        item.status = Labs.ReferenceRangeMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeMilestoneStatus.created) }
    }
}
