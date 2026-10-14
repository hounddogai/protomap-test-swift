@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySnapshotTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newModalitySnapshot("code-636", title: "title-239")
        #expect(item.status == Imaging.ModalitySnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newModalitySnapshot("code-636", title: "title-239")
        try item.moveTo(Imaging.ModalitySnapshotStatus.pending)
        #expect(item.status == Imaging.ModalitySnapshotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newModalitySnapshot("code-636", title: "title-239")
        item.status = Imaging.ModalitySnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalitySnapshotStatus.draft) }
    }
}
