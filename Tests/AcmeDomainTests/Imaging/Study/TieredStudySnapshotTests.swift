@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudySnapshotTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newTieredStudySnapshot("code-114", title: "title-985")
        #expect(item.status == Imaging.TieredStudySnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newTieredStudySnapshot("code-114", title: "title-985")
        try item.moveTo(Imaging.TieredStudySnapshotStatus.inReview)
        #expect(item.status == Imaging.TieredStudySnapshotStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newTieredStudySnapshot("code-114", title: "title-985")
        item.status = Imaging.TieredStudySnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredStudySnapshotStatus.`open`) }
    }
}
