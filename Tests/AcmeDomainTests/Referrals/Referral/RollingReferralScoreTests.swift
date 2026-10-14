@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingReferralScoreTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRollingReferralScore("code-562", label: "label-379")
        #expect(item.status == Referrals.RollingReferralScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newRollingReferralScore("code-562", label: "label-379")
        try item.moveTo(Referrals.RollingReferralScoreStatus.approved)
        #expect(item.status == Referrals.RollingReferralScoreStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRollingReferralScore("code-562", label: "label-379")
        item.status = Referrals.RollingReferralScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingReferralScoreStatus.proposed) }
    }
}
