@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotReviewTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSlotReview("code-904", name: "name-53")
        #expect(item.status == Referrals.SlotReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newSlotReview("code-904", name: "name-53")
        try item.moveTo(Referrals.SlotReviewStatus.queued)
        #expect(item.status == Referrals.SlotReviewStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSlotReview("code-904", name: "name-53")
        item.status = Referrals.SlotReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotReviewStatus.new) }
    }
}
