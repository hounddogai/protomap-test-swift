@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkPlanTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newNetworkPlan("code-434", name: "name-56")
        #expect(item.status == Referrals.NetworkPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newNetworkPlan("code-434", name: "name-56")
        try item.moveTo(Referrals.NetworkPlanStatus.scheduled)
        #expect(item.status == Referrals.NetworkPlanStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newNetworkPlan("code-434", name: "name-56")
        item.status = Referrals.NetworkPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkPlanStatus.planned) }
    }
}
