@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadSnapshotTests {
    @Test func startsInNew() throws {
        let item = Imaging.newStrictReadSnapshot("code-36", title: "title-302")
        #expect(item.status == Imaging.StrictReadSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newStrictReadSnapshot("code-36", title: "title-302")
        try item.moveTo(Imaging.StrictReadSnapshotStatus.running)
        #expect(item.status == Imaging.StrictReadSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newStrictReadSnapshot("code-36", title: "title-302")
        item.status = Imaging.StrictReadSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictReadSnapshotStatus.new) }
    }
}
