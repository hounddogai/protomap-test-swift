@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotWindowTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSlotWindow("code-406", label: "label-744")
        #expect(item.status == Referrals.SlotWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Referrals.newSlotWindow("code-406", label: "label-744")
        try item.moveTo(Referrals.SlotWindowStatus.closed)
        #expect(item.status == Referrals.SlotWindowStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSlotWindow("code-406", label: "label-744")
        item.status = Referrals.SlotWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotWindowStatus.draft) }
    }
}
