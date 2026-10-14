@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureLedgerTests {
    @Test func startsInNew() throws {
        let item = Referrals.newClosureLedger("code-919", name: "name-570")
        #expect(item.status == Referrals.ClosureLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newClosureLedger("code-919", name: "name-570")
        try item.moveTo(Referrals.ClosureLedgerStatus.done)
        #expect(item.status == Referrals.ClosureLedgerStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newClosureLedger("code-919", name: "name-570")
        item.status = Referrals.ClosureLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureLedgerStatus.new) }
    }
}
