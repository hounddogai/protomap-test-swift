@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralClaimTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newGlobalReferralClaim("code-86", name: "name-591")
        #expect(item.status == Referrals.GlobalReferralClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newGlobalReferralClaim("code-86", name: "name-591")
        try item.moveTo(Referrals.GlobalReferralClaimStatus.granted)
        #expect(item.status == Referrals.GlobalReferralClaimStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newGlobalReferralClaim("code-86", name: "name-591")
        item.status = Referrals.GlobalReferralClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalReferralClaimStatus.requested) }
    }
}
