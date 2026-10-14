@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotCycleTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSlotCycle("code-66", name: "name-237")
        #expect(item.status == Referrals.SlotCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newSlotCycle("code-66", name: "name-237")
        try item.moveTo(Referrals.SlotCycleStatus.pending)
        #expect(item.status == Referrals.SlotCycleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSlotCycle("code-66", name: "name-237")
        item.status = Referrals.SlotCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotCycleStatus.draft) }
    }
}
