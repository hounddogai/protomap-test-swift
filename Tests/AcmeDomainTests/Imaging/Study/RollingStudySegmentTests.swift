@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudySegmentTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newRollingStudySegment("code-393", name: "name-649")
        #expect(item.status == Imaging.RollingStudySegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newRollingStudySegment("code-393", name: "name-649")
        try item.moveTo(Imaging.RollingStudySegmentStatus.inProgress)
        #expect(item.status == Imaging.RollingStudySegmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newRollingStudySegment("code-393", name: "name-649")
        item.status = Imaging.RollingStudySegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingStudySegmentStatus.planned) }
    }
}
