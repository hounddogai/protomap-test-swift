@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralDigestTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newReferralDigest("code-99", label: "label-990")
        #expect(item.status == Referrals.ReferralDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newReferralDigest("code-99", label: "label-990")
        try item.moveTo(Referrals.ReferralDigestStatus.revoked)
        #expect(item.status == Referrals.ReferralDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newReferralDigest("code-99", label: "label-990")
        item.status = Referrals.ReferralDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralDigestStatus.requested) }
    }
}
