@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictDisclosureLedgerTests {
    @Test func startsInCreated() throws {
        let item = Consent.newStrictDisclosureLedger("code-132", name: "name-555")
        #expect(item.status == Consent.StrictDisclosureLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newStrictDisclosureLedger("code-132", name: "name-555")
        try item.moveTo(Consent.StrictDisclosureLedgerStatus.validated)
        #expect(item.status == Consent.StrictDisclosureLedgerStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newStrictDisclosureLedger("code-132", name: "name-555")
        item.status = Consent.StrictDisclosureLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictDisclosureLedgerStatus.created) }
    }
}
