@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeReviewTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newChargeReview("code-529", name: "name-253")
        #expect(item.status == RevenueCycle.ChargeReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newChargeReview("code-529", name: "name-253")
        try item.moveTo(RevenueCycle.ChargeReviewStatus.active)
        #expect(item.status == RevenueCycle.ChargeReviewStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newChargeReview("code-529", name: "name-253")
        item.status = RevenueCycle.ChargeReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeReviewStatus.draft) }
    }
}
