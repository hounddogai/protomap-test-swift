@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityPlanTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newScheduledEligibilityPlan("code-702", name: "name-673")
        #expect(item.status == Referrals.ScheduledEligibilityPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newScheduledEligibilityPlan("code-702", name: "name-673")
        try item.moveTo(Referrals.ScheduledEligibilityPlanStatus.revoked)
        #expect(item.status == Referrals.ScheduledEligibilityPlanStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newScheduledEligibilityPlan("code-702", name: "name-673")
        item.status = Referrals.ScheduledEligibilityPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledEligibilityPlanStatus.requested) }
    }
}
