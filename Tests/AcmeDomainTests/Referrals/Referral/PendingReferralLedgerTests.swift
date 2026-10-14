@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralLedgerTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newPendingReferralLedger("code-97", label: "label-68")
        #expect(item.status == Referrals.PendingReferralLedgerStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Referrals.newPendingReferralLedger("code-97", label: "label-68")
        try item.moveTo(Referrals.PendingReferralLedgerStatus.cancelled)
        #expect(item.status == Referrals.PendingReferralLedgerStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newPendingReferralLedger("code-97", label: "label-68")
        item.status = Referrals.PendingReferralLedgerStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingReferralLedgerStatus.planned) }
    }
}
