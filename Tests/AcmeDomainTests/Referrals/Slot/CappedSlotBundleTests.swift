@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedSlotBundleTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newCappedSlotBundle("code-981", name: "name-863")
        #expect(item.status == Referrals.CappedSlotBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newCappedSlotBundle("code-981", name: "name-863")
        try item.moveTo(Referrals.CappedSlotBundleStatus.pending)
        #expect(item.status == Referrals.CappedSlotBundleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newCappedSlotBundle("code-981", name: "name-863")
        item.status = Referrals.CappedSlotBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedSlotBundleStatus.draft) }
    }
}
