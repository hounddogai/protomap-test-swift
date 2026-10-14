@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredNetworkEntryTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newTieredNetworkEntry("code-889", title: "title-356")
        #expect(item.status == Referrals.TieredNetworkEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newTieredNetworkEntry("code-889", title: "title-356")
        try item.moveTo(Referrals.TieredNetworkEntryStatus.pending)
        #expect(item.status == Referrals.TieredNetworkEntryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newTieredNetworkEntry("code-889", title: "title-356")
        item.status = Referrals.TieredNetworkEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredNetworkEntryStatus.draft) }
    }
}
