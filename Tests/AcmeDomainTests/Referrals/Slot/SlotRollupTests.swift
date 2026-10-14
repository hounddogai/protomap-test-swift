@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotRollupTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSlotRollup("code-508", title: "title-190")
        #expect(item.status == Referrals.SlotRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newSlotRollup("code-508", title: "title-190")
        try item.moveTo(Referrals.SlotRollupStatus.suspended)
        #expect(item.status == Referrals.SlotRollupStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSlotRollup("code-508", title: "title-190")
        item.status = Referrals.SlotRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotRollupStatus.draft) }
    }
}
