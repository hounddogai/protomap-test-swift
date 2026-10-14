@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimReviewTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newTieredClaimReview("code-522", label: "label-357")
        #expect(item.status == RevenueCycle.TieredClaimReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newTieredClaimReview("code-522", label: "label-357")
        try item.moveTo(RevenueCycle.TieredClaimReviewStatus.granted)
        #expect(item.status == RevenueCycle.TieredClaimReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newTieredClaimReview("code-522", label: "label-357")
        item.status = RevenueCycle.TieredClaimReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredClaimReviewStatus.requested) }
    }
}
