@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralDigestTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newTieredReferralDigest("code-653", title: "title-813")
        #expect(item.status == Referrals.TieredReferralDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newTieredReferralDigest("code-653", title: "title-813")
        try item.moveTo(Referrals.TieredReferralDigestStatus.suspended)
        #expect(item.status == Referrals.TieredReferralDigestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newTieredReferralDigest("code-653", title: "title-813")
        item.status = Referrals.TieredReferralDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredReferralDigestStatus.draft) }
    }
}
