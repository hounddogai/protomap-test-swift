@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultClosureLedgerTests {
    @Test func startsInNew() throws {
        let item = Referrals.newDefaultClosureLedger("code-62", title: "title-615")
        #expect(item.status == Referrals.DefaultClosureLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newDefaultClosureLedger("code-62", title: "title-615")
        try item.moveTo(Referrals.DefaultClosureLedgerStatus.running)
        #expect(item.status == Referrals.DefaultClosureLedgerStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newDefaultClosureLedger("code-62", title: "title-615")
        item.status = Referrals.DefaultClosureLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultClosureLedgerStatus.new) }
    }
}
