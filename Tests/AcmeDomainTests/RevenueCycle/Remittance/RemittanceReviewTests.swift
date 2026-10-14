@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceReviewTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newRemittanceReview("code-354", title: "title-68")
        #expect(item.status == RevenueCycle.RemittanceReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newRemittanceReview("code-354", title: "title-68")
        try item.moveTo(RevenueCycle.RemittanceReviewStatus.suspended)
        #expect(item.status == RevenueCycle.RemittanceReviewStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newRemittanceReview("code-354", title: "title-68")
        item.status = RevenueCycle.RemittanceReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceReviewStatus.draft) }
    }
}
