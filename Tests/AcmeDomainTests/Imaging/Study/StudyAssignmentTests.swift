@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newStudyAssignment("code-876", name: "name-839")
        #expect(item.status == Imaging.StudyAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newStudyAssignment("code-876", name: "name-839")
        try item.moveTo(Imaging.StudyAssignmentStatus.ready)
        #expect(item.status == Imaging.StudyAssignmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newStudyAssignment("code-876", name: "name-839")
        item.status = Imaging.StudyAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyAssignmentStatus.idle) }
    }
}
