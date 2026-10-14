@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFollowUpAdjustment("code-908", name: "name-15")
        #expect(item.status == Referrals.FollowUpAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newFollowUpAdjustment("code-908", name: "name-15")
        try item.moveTo(Referrals.FollowUpAdjustmentStatus.active)
        #expect(item.status == Referrals.FollowUpAdjustmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFollowUpAdjustment("code-908", name: "name-15")
        item.status = Referrals.FollowUpAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpAdjustmentStatus.draft) }
    }
}
