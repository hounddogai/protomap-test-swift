@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudySegmentTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newBatchedStudySegment("code-339", label: "label-57")
        #expect(item.status == Imaging.BatchedStudySegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newBatchedStudySegment("code-339", label: "label-57")
        try item.moveTo(Imaging.BatchedStudySegmentStatus.inProgress)
        #expect(item.status == Imaging.BatchedStudySegmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newBatchedStudySegment("code-339", label: "label-57")
        item.status = Imaging.BatchedStudySegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.BatchedStudySegmentStatus.planned) }
    }
}
