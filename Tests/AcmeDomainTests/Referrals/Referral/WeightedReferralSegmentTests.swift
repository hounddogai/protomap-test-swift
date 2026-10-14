@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralSegmentTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newWeightedReferralSegment("code-839", title: "title-688")
        #expect(item.status == Referrals.WeightedReferralSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newWeightedReferralSegment("code-839", title: "title-688")
        try item.moveTo(Referrals.WeightedReferralSegmentStatus.revoked)
        #expect(item.status == Referrals.WeightedReferralSegmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newWeightedReferralSegment("code-839", title: "title-688")
        item.status = Referrals.WeightedReferralSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedReferralSegmentStatus.requested) }
    }
}
