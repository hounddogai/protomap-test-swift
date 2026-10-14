@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultReferralClaimTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newDefaultReferralClaim("code-258", title: "title-673")
        #expect(item.status == Referrals.DefaultReferralClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newDefaultReferralClaim("code-258", title: "title-673")
        try item.moveTo(Referrals.DefaultReferralClaimStatus.granted)
        #expect(item.status == Referrals.DefaultReferralClaimStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newDefaultReferralClaim("code-258", title: "title-673")
        item.status = Referrals.DefaultReferralClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultReferralClaimStatus.requested) }
    }
}
