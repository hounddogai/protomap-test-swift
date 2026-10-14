@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveReferralClaimTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newAdaptiveReferralClaim("code-835", title: "title-919")
        #expect(item.status == Referrals.AdaptiveReferralClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newAdaptiveReferralClaim("code-835", title: "title-919")
        try item.moveTo(Referrals.AdaptiveReferralClaimStatus.rejected)
        #expect(item.status == Referrals.AdaptiveReferralClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newAdaptiveReferralClaim("code-835", title: "title-919")
        item.status = Referrals.AdaptiveReferralClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveReferralClaimStatus.proposed) }
    }
}
