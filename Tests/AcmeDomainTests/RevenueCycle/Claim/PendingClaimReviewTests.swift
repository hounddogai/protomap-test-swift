@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingClaimReviewTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newPendingClaimReview("code-540", title: "title-820")
        #expect(item.status == RevenueCycle.PendingClaimReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newPendingClaimReview("code-540", title: "title-820")
        try item.moveTo(RevenueCycle.PendingClaimReviewStatus.running)
        #expect(item.status == RevenueCycle.PendingClaimReviewStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newPendingClaimReview("code-540", title: "title-820")
        item.status = RevenueCycle.PendingClaimReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingClaimReviewStatus.new) }
    }
}
