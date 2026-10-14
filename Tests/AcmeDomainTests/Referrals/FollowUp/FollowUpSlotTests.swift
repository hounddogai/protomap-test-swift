@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpSlotTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFollowUpSlot("code-416", title: "title-913")
        #expect(item.status == Referrals.FollowUpSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newFollowUpSlot("code-416", title: "title-913")
        try item.moveTo(Referrals.FollowUpSlotStatus.pending)
        #expect(item.status == Referrals.FollowUpSlotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFollowUpSlot("code-416", title: "title-913")
        item.status = Referrals.FollowUpSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpSlotStatus.draft) }
    }
}
