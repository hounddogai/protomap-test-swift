@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyNoticeTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newStudyNotice("code-31", name: "name-547")
        #expect(item.status == Imaging.StudyNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newStudyNotice("code-31", name: "name-547")
        try item.moveTo(Imaging.StudyNoticeStatus.granted)
        #expect(item.status == Imaging.StudyNoticeStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newStudyNotice("code-31", name: "name-547")
        item.status = Imaging.StudyNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyNoticeStatus.requested) }
    }
}
