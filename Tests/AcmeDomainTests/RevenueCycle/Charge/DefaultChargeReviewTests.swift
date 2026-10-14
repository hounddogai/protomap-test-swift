@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeReviewTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDefaultChargeReview("code-285", label: "label-531")
        #expect(item.status == RevenueCycle.DefaultChargeReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newDefaultChargeReview("code-285", label: "label-531")
        try item.moveTo(RevenueCycle.DefaultChargeReviewStatus.warming)
        #expect(item.status == RevenueCycle.DefaultChargeReviewStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDefaultChargeReview("code-285", label: "label-531")
        item.status = RevenueCycle.DefaultChargeReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultChargeReviewStatus.idle) }
    }
}
