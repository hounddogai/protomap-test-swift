@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralPlanTests {
    @Test func startsInNew() throws {
        let item = Referrals.newReferralPlan("code-781", title: "title-629")
        #expect(item.status == Referrals.ReferralPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newReferralPlan("code-781", title: "title-629")
        try item.moveTo(Referrals.ReferralPlanStatus.queued)
        #expect(item.status == Referrals.ReferralPlanStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newReferralPlan("code-781", title: "title-629")
        item.status = Referrals.ReferralPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralPlanStatus.new) }
    }
}
