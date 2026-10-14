@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRollupTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newStudyRollup("code-318", title: "title-457")
        #expect(item.status == Imaging.StudyRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newStudyRollup("code-318", title: "title-457")
        try item.moveTo(Imaging.StudyRollupStatus.warming)
        #expect(item.status == Imaging.StudyRollupStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newStudyRollup("code-318", title: "title-457")
        item.status = Imaging.StudyRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyRollupStatus.idle) }
    }
}
