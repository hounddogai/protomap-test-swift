@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadQuotaTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newTieredReadQuota("code-874", title: "title-150")
        #expect(item.status == Imaging.TieredReadQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newTieredReadQuota("code-874", title: "title-150")
        try item.moveTo(Imaging.TieredReadQuotaStatus.pending)
        #expect(item.status == Imaging.TieredReadQuotaStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newTieredReadQuota("code-874", title: "title-150")
        item.status = Imaging.TieredReadQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredReadQuotaStatus.draft) }
    }
}
