@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadLedgerTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newAdaptiveReadLedger("code-950", label: "label-124")
        #expect(item.status == Imaging.AdaptiveReadLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newAdaptiveReadLedger("code-950", label: "label-124")
        try item.moveTo(Imaging.AdaptiveReadLedgerStatus.active)
        #expect(item.status == Imaging.AdaptiveReadLedgerStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newAdaptiveReadLedger("code-950", label: "label-124")
        item.status = Imaging.AdaptiveReadLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveReadLedgerStatus.draft) }
    }
}
