@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistMilestone("code-386", title: "title-149")
        #expect(item.status == Imaging.WorklistMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWorklistMilestone("code-386", title: "title-149")
        try item.moveTo(Imaging.WorklistMilestoneStatus.validated)
        #expect(item.status == Imaging.WorklistMilestoneStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistMilestone("code-386", title: "title-149")
        item.status = Imaging.WorklistMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistMilestoneStatus.created) }
    }
}
