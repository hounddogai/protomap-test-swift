@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkScoreTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRegionalNetworkScore("code-738", name: "name-148")
        #expect(item.status == Referrals.RegionalNetworkScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newRegionalNetworkScore("code-738", name: "name-148")
        try item.moveTo(Referrals.RegionalNetworkScoreStatus.approved)
        #expect(item.status == Referrals.RegionalNetworkScoreStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRegionalNetworkScore("code-738", name: "name-148")
        item.status = Referrals.RegionalNetworkScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalNetworkScoreStatus.proposed) }
    }
}
