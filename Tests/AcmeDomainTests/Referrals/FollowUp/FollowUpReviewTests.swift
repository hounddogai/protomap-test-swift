@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpReviewTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFollowUpReview("code-103", label: "label-787")
        #expect(item.status == Referrals.FollowUpReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newFollowUpReview("code-103", label: "label-787")
        try item.moveTo(Referrals.FollowUpReviewStatus.revoked)
        #expect(item.status == Referrals.FollowUpReviewStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFollowUpReview("code-103", label: "label-787")
        item.status = Referrals.FollowUpReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpReviewStatus.requested) }
    }
}
