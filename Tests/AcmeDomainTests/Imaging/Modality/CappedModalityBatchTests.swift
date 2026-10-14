@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityBatchTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCappedModalityBatch("code-673", name: "name-866")
        #expect(item.status == Imaging.CappedModalityBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newCappedModalityBatch("code-673", name: "name-866")
        try item.moveTo(Imaging.CappedModalityBatchStatus.suspended)
        #expect(item.status == Imaging.CappedModalityBatchStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCappedModalityBatch("code-673", name: "name-866")
        item.status = Imaging.CappedModalityBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityBatchStatus.draft) }
    }
}
