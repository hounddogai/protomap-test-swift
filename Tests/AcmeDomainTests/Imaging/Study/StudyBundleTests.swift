@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyBundleTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newStudyBundle("code-740", label: "label-986")
        #expect(item.status == Imaging.StudyBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newStudyBundle("code-740", label: "label-986")
        try item.moveTo(Imaging.StudyBundleStatus.scheduled)
        #expect(item.status == Imaging.StudyBundleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newStudyBundle("code-740", label: "label-986")
        item.status = Imaging.StudyBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyBundleStatus.planned) }
    }
}
