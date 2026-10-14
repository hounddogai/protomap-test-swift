@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRecordTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newStudyRecord("code-714", label: "label-32")
        #expect(item.status == Imaging.StudyRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newStudyRecord("code-714", label: "label-32")
        try item.moveTo(Imaging.StudyRecordStatus.granted)
        #expect(item.status == Imaging.StudyRecordStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newStudyRecord("code-714", label: "label-32")
        item.status = Imaging.StudyRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyRecordStatus.requested) }
    }
}
