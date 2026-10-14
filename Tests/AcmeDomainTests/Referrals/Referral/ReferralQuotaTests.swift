@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralQuotaTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newReferralQuota("code-526", title: "title-730")
        #expect(item.status == Referrals.ReferralQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newReferralQuota("code-526", title: "title-730")
        try item.moveTo(Referrals.ReferralQuotaStatus.rejected)
        #expect(item.status == Referrals.ReferralQuotaStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newReferralQuota("code-526", title: "title-730")
        item.status = Referrals.ReferralQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralQuotaStatus.proposed) }
    }
}
