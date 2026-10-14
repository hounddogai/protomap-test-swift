@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationLedgerTests {
    @Test func startsInNew() throws {
        let item = Consent.newCappedRevocationLedger("code-691", name: "name-707")
        #expect(item.status == Consent.CappedRevocationLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newCappedRevocationLedger("code-691", name: "name-707")
        try item.moveTo(Consent.CappedRevocationLedgerStatus.queued)
        #expect(item.status == Consent.CappedRevocationLedgerStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newCappedRevocationLedger("code-691", name: "name-707")
        item.status = Consent.CappedRevocationLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedRevocationLedgerStatus.new) }
    }
}
