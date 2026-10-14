@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotReviewTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newRegionalSlotReview("code-921", title: "title-782")
        #expect(item.status == Referrals.RegionalSlotReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newRegionalSlotReview("code-921", title: "title-782")
        try item.moveTo(Referrals.RegionalSlotReviewStatus.ready)
        #expect(item.status == Referrals.RegionalSlotReviewStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newRegionalSlotReview("code-921", title: "title-782")
        item.status = Referrals.RegionalSlotReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalSlotReviewStatus.idle) }
    }
}
