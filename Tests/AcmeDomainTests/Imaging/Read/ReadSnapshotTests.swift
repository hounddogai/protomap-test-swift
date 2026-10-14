@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadSnapshotTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newReadSnapshot("code-276", title: "title-992")
        #expect(item.status == Imaging.ReadSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newReadSnapshot("code-276", title: "title-992")
        try item.moveTo(Imaging.ReadSnapshotStatus.published)
        #expect(item.status == Imaging.ReadSnapshotStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newReadSnapshot("code-276", title: "title-992")
        item.status = Imaging.ReadSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadSnapshotStatus.created) }
    }
}
