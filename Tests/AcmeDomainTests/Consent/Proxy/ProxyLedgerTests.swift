@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyLedgerTests {
    @Test func startsInDraft() throws {
        let item = Consent.newProxyLedger("code-237", label: "label-883")
        #expect(item.status == Consent.ProxyLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Consent.newProxyLedger("code-237", label: "label-883")
        try item.moveTo(Consent.ProxyLedgerStatus.closed)
        #expect(item.status == Consent.ProxyLedgerStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newProxyLedger("code-237", label: "label-883")
        item.status = Consent.ProxyLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyLedgerStatus.draft) }
    }
}
