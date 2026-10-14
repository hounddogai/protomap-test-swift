@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newReferralPolicy("code-396", title: "title-259")
        #expect(item.status == Referrals.ReferralPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newReferralPolicy("code-396", title: "title-259")
        try item.moveTo(Referrals.ReferralPolicyStatus.inProgress)
        #expect(item.status == Referrals.ReferralPolicyStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newReferralPolicy("code-396", title: "title-259")
        item.status = Referrals.ReferralPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralPolicyStatus.planned) }
    }
}
