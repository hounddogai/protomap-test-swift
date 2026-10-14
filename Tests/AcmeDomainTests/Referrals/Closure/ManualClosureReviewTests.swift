@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureReviewTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newManualClosureReview("code-595", name: "name-880")
        #expect(item.status == Referrals.ManualClosureReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newManualClosureReview("code-595", name: "name-880")
        try item.moveTo(Referrals.ManualClosureReviewStatus.granted)
        #expect(item.status == Referrals.ManualClosureReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newManualClosureReview("code-595", name: "name-880")
        item.status = Referrals.ManualClosureReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualClosureReviewStatus.requested) }
    }
}
