@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalChargeReviewTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newGlobalChargeReview("code-672", name: "name-168")
        #expect(item.status == RevenueCycle.GlobalChargeReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newGlobalChargeReview("code-672", name: "name-168")
        try item.moveTo(RevenueCycle.GlobalChargeReviewStatus.published)
        #expect(item.status == RevenueCycle.GlobalChargeReviewStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newGlobalChargeReview("code-672", name: "name-168")
        item.status = RevenueCycle.GlobalChargeReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalChargeReviewStatus.created) }
    }
}
