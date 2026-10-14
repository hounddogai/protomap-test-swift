@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotOverrideTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSlotOverride("code-916", title: "title-359")
        #expect(item.status == Referrals.SlotOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newSlotOverride("code-916", title: "title-359")
        try item.moveTo(Referrals.SlotOverrideStatus.suspended)
        #expect(item.status == Referrals.SlotOverrideStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSlotOverride("code-916", title: "title-359")
        item.status = Referrals.SlotOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotOverrideStatus.draft) }
    }
}
