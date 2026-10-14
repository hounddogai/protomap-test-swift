@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotLedgerTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSlotLedger("code-212", name: "name-233")
        #expect(item.status == Referrals.SlotLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newSlotLedger("code-212", name: "name-233")
        try item.moveTo(Referrals.SlotLedgerStatus.queued)
        #expect(item.status == Referrals.SlotLedgerStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSlotLedger("code-212", name: "name-233")
        item.status = Referrals.SlotLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotLedgerStatus.new) }
    }
}
