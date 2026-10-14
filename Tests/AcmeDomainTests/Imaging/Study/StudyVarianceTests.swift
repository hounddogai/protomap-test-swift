@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyVarianceTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newStudyVariance("code-666", title: "title-711")
        #expect(item.status == Imaging.StudyVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newStudyVariance("code-666", title: "title-711")
        try item.moveTo(Imaging.StudyVarianceStatus.resolved)
        #expect(item.status == Imaging.StudyVarianceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newStudyVariance("code-666", title: "title-711")
        item.status = Imaging.StudyVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyVarianceStatus.`open`) }
    }
}
