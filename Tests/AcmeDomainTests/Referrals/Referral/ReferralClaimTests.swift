@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralClaimTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newReferralClaim("code-103", name: "name-122")
        #expect(item.status == Referrals.ReferralClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newReferralClaim("code-103", name: "name-122")
        try item.moveTo(Referrals.ReferralClaimStatus.approved)
        #expect(item.status == Referrals.ReferralClaimStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newReferralClaim("code-103", name: "name-122")
        item.status = Referrals.ReferralClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralClaimStatus.proposed) }
    }
}
