@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureLedgerTests {
    @Test func startsInDraft() throws {
        let item = Consent.newDisclosureLedger("code-976", label: "label-669")
        #expect(item.status == Consent.DisclosureLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newDisclosureLedger("code-976", label: "label-669")
        try item.moveTo(Consent.DisclosureLedgerStatus.pending)
        #expect(item.status == Consent.DisclosureLedgerStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newDisclosureLedger("code-976", label: "label-669")
        item.status = Consent.DisclosureLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureLedgerStatus.draft) }
    }
}
