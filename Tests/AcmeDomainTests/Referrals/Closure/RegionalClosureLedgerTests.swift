@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalClosureLedgerTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newRegionalClosureLedger("code-487", title: "title-670")
        #expect(item.status == Referrals.RegionalClosureLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newRegionalClosureLedger("code-487", title: "title-670")
        try item.moveTo(Referrals.RegionalClosureLedgerStatus.pending)
        #expect(item.status == Referrals.RegionalClosureLedgerStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newRegionalClosureLedger("code-487", title: "title-670")
        item.status = Referrals.RegionalClosureLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalClosureLedgerStatus.draft) }
    }
}
