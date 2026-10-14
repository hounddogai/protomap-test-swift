@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBatchTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newModalityBatch("code-729", title: "title-399")
        #expect(item.status == Imaging.ModalityBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newModalityBatch("code-729", title: "title-399")
        try item.moveTo(Imaging.ModalityBatchStatus.pending)
        #expect(item.status == Imaging.ModalityBatchStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newModalityBatch("code-729", title: "title-399")
        item.status = Imaging.ModalityBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityBatchStatus.draft) }
    }
}
