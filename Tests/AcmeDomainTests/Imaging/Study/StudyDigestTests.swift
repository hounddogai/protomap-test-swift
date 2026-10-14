@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyDigestTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newStudyDigest("code-707", title: "title-742")
        #expect(item.status == Imaging.StudyDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newStudyDigest("code-707", title: "title-742")
        try item.moveTo(Imaging.StudyDigestStatus.warming)
        #expect(item.status == Imaging.StudyDigestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newStudyDigest("code-707", title: "title-742")
        item.status = Imaging.StudyDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyDigestStatus.idle) }
    }
}
