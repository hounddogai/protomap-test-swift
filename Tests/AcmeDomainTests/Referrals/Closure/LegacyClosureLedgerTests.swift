@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyClosureLedgerTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newLegacyClosureLedger("code-532", name: "name-368")
        #expect(item.status == Referrals.LegacyClosureLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newLegacyClosureLedger("code-532", name: "name-368")
        try item.moveTo(Referrals.LegacyClosureLedgerStatus.warming)
        #expect(item.status == Referrals.LegacyClosureLedgerStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newLegacyClosureLedger("code-532", name: "name-368")
        item.status = Referrals.LegacyClosureLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyClosureLedgerStatus.idle) }
    }
}
