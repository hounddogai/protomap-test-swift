@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotLedgerTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newDefaultSlotLedger("code-725", label: "label-735")
        #expect(item.status == Referrals.DefaultSlotLedgerStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newDefaultSlotLedger("code-725", label: "label-735")
        try item.moveTo(Referrals.DefaultSlotLedgerStatus.inProgress)
        #expect(item.status == Referrals.DefaultSlotLedgerStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newDefaultSlotLedger("code-725", label: "label-735")
        item.status = Referrals.DefaultSlotLedgerStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultSlotLedgerStatus.planned) }
    }
}
