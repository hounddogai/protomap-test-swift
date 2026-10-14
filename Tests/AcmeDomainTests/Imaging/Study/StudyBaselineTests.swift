@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyBaselineTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newStudyBaseline("code-524", label: "label-651")
        #expect(item.status == Imaging.StudyBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newStudyBaseline("code-524", label: "label-651")
        try item.moveTo(Imaging.StudyBaselineStatus.resolved)
        #expect(item.status == Imaging.StudyBaselineStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newStudyBaseline("code-524", label: "label-651")
        item.status = Imaging.StudyBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyBaselineStatus.`open`) }
    }
}
