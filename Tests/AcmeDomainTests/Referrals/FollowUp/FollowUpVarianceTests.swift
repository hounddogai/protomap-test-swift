@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpVarianceTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFollowUpVariance("code-392", name: "name-975")
        #expect(item.status == Referrals.FollowUpVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newFollowUpVariance("code-392", name: "name-975")
        try item.moveTo(Referrals.FollowUpVarianceStatus.revoked)
        #expect(item.status == Referrals.FollowUpVarianceStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFollowUpVariance("code-392", name: "name-975")
        item.status = Referrals.FollowUpVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpVarianceStatus.requested) }
    }
}
