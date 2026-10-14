@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyScoreTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newStudyScore("code-347", title: "title-386")
        #expect(item.status == Imaging.StudyScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newStudyScore("code-347", title: "title-386")
        try item.moveTo(Imaging.StudyScoreStatus.inProgress)
        #expect(item.status == Imaging.StudyScoreStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newStudyScore("code-347", title: "title-386")
        item.status = Imaging.StudyScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyScoreStatus.planned) }
    }
}
