@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageLedgerTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLanguageLedger("code-102", name: "name-834")
        #expect(item.status == Consent.LanguageLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newLanguageLedger("code-102", name: "name-834")
        try item.moveTo(Consent.LanguageLedgerStatus.granted)
        #expect(item.status == Consent.LanguageLedgerStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLanguageLedger("code-102", name: "name-834")
        item.status = Consent.LanguageLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageLedgerStatus.requested) }
    }
}
