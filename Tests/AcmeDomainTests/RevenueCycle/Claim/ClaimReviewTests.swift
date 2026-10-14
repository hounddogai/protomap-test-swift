@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimReviewTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newClaimReview("code-315", name: "name-840")
        #expect(item.status == RevenueCycle.ClaimReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newClaimReview("code-315", name: "name-840")
        try item.moveTo(RevenueCycle.ClaimReviewStatus.running)
        #expect(item.status == RevenueCycle.ClaimReviewStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newClaimReview("code-315", name: "name-840")
        item.status = RevenueCycle.ClaimReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimReviewStatus.new) }
    }
}
