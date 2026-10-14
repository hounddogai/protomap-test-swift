@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPrimaryWorklistMilestone("code-376", label: "label-319")
        #expect(item.status == Imaging.PrimaryWorklistMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newPrimaryWorklistMilestone("code-376", label: "label-319")
        try item.moveTo(Imaging.PrimaryWorklistMilestoneStatus.retired)
        #expect(item.status == Imaging.PrimaryWorklistMilestoneStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPrimaryWorklistMilestone("code-376", label: "label-319")
        item.status = Imaging.PrimaryWorklistMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryWorklistMilestoneStatus.created) }
    }
}
