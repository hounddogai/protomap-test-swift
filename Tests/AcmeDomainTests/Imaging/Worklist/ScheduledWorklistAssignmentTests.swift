@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledWorklistAssignmentTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newScheduledWorklistAssignment("code-280", name: "name-556")
        #expect(item.status == Imaging.ScheduledWorklistAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newScheduledWorklistAssignment("code-280", name: "name-556")
        try item.moveTo(Imaging.ScheduledWorklistAssignmentStatus.reopened)
        #expect(item.status == Imaging.ScheduledWorklistAssignmentStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newScheduledWorklistAssignment("code-280", name: "name-556")
        item.status = Imaging.ScheduledWorklistAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledWorklistAssignmentStatus.`open`) }
    }
}
