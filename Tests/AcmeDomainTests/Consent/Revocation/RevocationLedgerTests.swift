@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationLedgerTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRevocationLedger("code-517", title: "title-854")
        #expect(item.status == Consent.RevocationLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Consent.newRevocationLedger("code-517", title: "title-854")
        try item.moveTo(Consent.RevocationLedgerStatus.retired)
        #expect(item.status == Consent.RevocationLedgerStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRevocationLedger("code-517", title: "title-854")
        item.status = Consent.RevocationLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationLedgerStatus.created) }
    }
}
