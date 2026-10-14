@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpTierTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newTieredFollowUpTier("code-952", name: "name-378")
        #expect(item.status == Referrals.TieredFollowUpTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newTieredFollowUpTier("code-952", name: "name-378")
        try item.moveTo(Referrals.TieredFollowUpTierStatus.pending)
        #expect(item.status == Referrals.TieredFollowUpTierStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newTieredFollowUpTier("code-952", name: "name-378")
        item.status = Referrals.TieredFollowUpTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredFollowUpTierStatus.draft) }
    }
}
