@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPlanTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newManualNetworkPlan("code-54", name: "name-332")
        #expect(item.status == Referrals.ManualNetworkPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newManualNetworkPlan("code-54", name: "name-332")
        try item.moveTo(Referrals.ManualNetworkPlanStatus.revoked)
        #expect(item.status == Referrals.ManualNetworkPlanStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newManualNetworkPlan("code-54", name: "name-332")
        item.status = Referrals.ManualNetworkPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkPlanStatus.requested) }
    }
}
