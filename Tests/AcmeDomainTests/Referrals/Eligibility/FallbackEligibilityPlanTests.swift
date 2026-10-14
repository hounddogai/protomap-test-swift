@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackEligibilityPlanTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFallbackEligibilityPlan("code-207", title: "title-13")
        #expect(item.status == Referrals.FallbackEligibilityPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newFallbackEligibilityPlan("code-207", title: "title-13")
        try item.moveTo(Referrals.FallbackEligibilityPlanStatus.revoked)
        #expect(item.status == Referrals.FallbackEligibilityPlanStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFallbackEligibilityPlan("code-207", title: "title-13")
        item.status = Referrals.FallbackEligibilityPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackEligibilityPlanStatus.requested) }
    }
}
