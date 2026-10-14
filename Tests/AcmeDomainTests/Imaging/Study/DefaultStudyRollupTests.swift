@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultStudyRollupTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newDefaultStudyRollup("code-364", label: "label-804")
        #expect(item.status == Imaging.DefaultStudyRollupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newDefaultStudyRollup("code-364", label: "label-804")
        try item.moveTo(Imaging.DefaultStudyRollupStatus.inReview)
        #expect(item.status == Imaging.DefaultStudyRollupStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newDefaultStudyRollup("code-364", label: "label-804")
        item.status = Imaging.DefaultStudyRollupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultStudyRollupStatus.`open`) }
    }
}
