@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityVarianceTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newCappedEligibilityVariance("code-211", name: "name-789")
        #expect(item.status == Referrals.CappedEligibilityVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newCappedEligibilityVariance("code-211", name: "name-789")
        try item.moveTo(Referrals.CappedEligibilityVarianceStatus.revoked)
        #expect(item.status == Referrals.CappedEligibilityVarianceStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newCappedEligibilityVariance("code-211", name: "name-789")
        item.status = Referrals.CappedEligibilityVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedEligibilityVarianceStatus.requested) }
    }
}
