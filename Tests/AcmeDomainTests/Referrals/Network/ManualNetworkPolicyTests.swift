@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPolicyTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newManualNetworkPolicy("code-960", name: "name-921")
        #expect(item.status == Referrals.ManualNetworkPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newManualNetworkPolicy("code-960", name: "name-921")
        try item.moveTo(Referrals.ManualNetworkPolicyStatus.inReview)
        #expect(item.status == Referrals.ManualNetworkPolicyStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newManualNetworkPolicy("code-960", name: "name-921")
        item.status = Referrals.ManualNetworkPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkPolicyStatus.`open`) }
    }
}
