@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackDenialReviewTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newFallbackDenialReview("code-891", label: "label-544")
        #expect(item.status == RevenueCycle.FallbackDenialReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newFallbackDenialReview("code-891", label: "label-544")
        try item.moveTo(RevenueCycle.FallbackDenialReviewStatus.revoked)
        #expect(item.status == RevenueCycle.FallbackDenialReviewStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newFallbackDenialReview("code-891", label: "label-544")
        item.status = RevenueCycle.FallbackDenialReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackDenialReviewStatus.requested) }
    }
}
