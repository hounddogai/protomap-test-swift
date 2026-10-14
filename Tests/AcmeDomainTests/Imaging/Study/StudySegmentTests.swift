@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySegmentTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newStudySegment("code-977", name: "name-96")
        #expect(item.status == Imaging.StudySegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newStudySegment("code-977", name: "name-96")
        try item.moveTo(Imaging.StudySegmentStatus.pending)
        #expect(item.status == Imaging.StudySegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newStudySegment("code-977", name: "name-96")
        item.status = Imaging.StudySegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudySegmentStatus.draft) }
    }
}
