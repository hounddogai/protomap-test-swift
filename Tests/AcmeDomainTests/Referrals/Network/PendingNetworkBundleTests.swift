@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkBundleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newPendingNetworkBundle("code-969", name: "name-442")
        #expect(item.status == Referrals.PendingNetworkBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newPendingNetworkBundle("code-969", name: "name-442")
        try item.moveTo(Referrals.PendingNetworkBundleStatus.approved)
        #expect(item.status == Referrals.PendingNetworkBundleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newPendingNetworkBundle("code-969", name: "name-442")
        item.status = Referrals.PendingNetworkBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingNetworkBundleStatus.proposed) }
    }
}
