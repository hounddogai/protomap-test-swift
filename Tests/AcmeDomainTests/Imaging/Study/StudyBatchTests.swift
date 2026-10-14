@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyBatchTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newStudyBatch("code-816", name: "name-376")
        #expect(item.status == Imaging.StudyBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newStudyBatch("code-816", name: "name-376")
        try item.moveTo(Imaging.StudyBatchStatus.granted)
        #expect(item.status == Imaging.StudyBatchStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newStudyBatch("code-816", name: "name-376")
        item.status = Imaging.StudyBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyBatchStatus.requested) }
    }
}
