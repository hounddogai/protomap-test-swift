@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialReviewTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialReview("code-660", name: "name-565")
        #expect(item.status == RevenueCycle.DenialReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newDenialReview("code-660", name: "name-565")
        try item.moveTo(RevenueCycle.DenialReviewStatus.approved)
        #expect(item.status == RevenueCycle.DenialReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialReview("code-660", name: "name-565")
        item.status = RevenueCycle.DenialReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialReviewStatus.proposed) }
    }
}
