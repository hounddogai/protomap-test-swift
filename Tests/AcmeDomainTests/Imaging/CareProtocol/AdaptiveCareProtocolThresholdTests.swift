@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolThresholdTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newAdaptiveCareProtocolThreshold("code-579", title: "title-782")
        #expect(item.status == Imaging.AdaptiveCareProtocolThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newAdaptiveCareProtocolThreshold("code-579", title: "title-782")
        try item.moveTo(Imaging.AdaptiveCareProtocolThresholdStatus.pending)
        #expect(item.status == Imaging.AdaptiveCareProtocolThresholdStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newAdaptiveCareProtocolThreshold("code-579", title: "title-782")
        item.status = Imaging.AdaptiveCareProtocolThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveCareProtocolThresholdStatus.draft) }
    }
}
