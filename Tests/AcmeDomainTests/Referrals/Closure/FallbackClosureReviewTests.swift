@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureReviewTests {
    @Test func startsInNew() throws {
        let item = Referrals.newFallbackClosureReview("code-369", label: "label-554")
        #expect(item.status == Referrals.FallbackClosureReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newFallbackClosureReview("code-369", label: "label-554")
        try item.moveTo(Referrals.FallbackClosureReviewStatus.queued)
        #expect(item.status == Referrals.FallbackClosureReviewStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newFallbackClosureReview("code-369", label: "label-554")
        item.status = Referrals.FallbackClosureReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackClosureReviewStatus.new) }
    }
}
