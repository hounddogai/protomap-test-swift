@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureLedgerTests {
    @Test func startsInDraft() throws {
        let item = Consent.newCappedDisclosureLedger("code-765", name: "name-50")
        #expect(item.status == Consent.CappedDisclosureLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newCappedDisclosureLedger("code-765", name: "name-50")
        try item.moveTo(Consent.CappedDisclosureLedgerStatus.active)
        #expect(item.status == Consent.CappedDisclosureLedgerStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newCappedDisclosureLedger("code-765", name: "name-50")
        item.status = Consent.CappedDisclosureLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedDisclosureLedgerStatus.draft) }
    }
}
