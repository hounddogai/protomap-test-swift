@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedDenialReviewTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newWeightedDenialReview("code-732", name: "name-334")
        #expect(item.status == RevenueCycle.WeightedDenialReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newWeightedDenialReview("code-732", name: "name-334")
        try item.moveTo(RevenueCycle.WeightedDenialReviewStatus.granted)
        #expect(item.status == RevenueCycle.WeightedDenialReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newWeightedDenialReview("code-732", name: "name-334")
        item.status = RevenueCycle.WeightedDenialReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedDenialReviewStatus.requested) }
    }
}
