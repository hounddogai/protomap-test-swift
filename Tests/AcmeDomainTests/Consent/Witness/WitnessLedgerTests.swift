@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessLedgerTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWitnessLedger("code-790", title: "title-588")
        #expect(item.status == Consent.WitnessLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newWitnessLedger("code-790", title: "title-588")
        try item.moveTo(Consent.WitnessLedgerStatus.validated)
        #expect(item.status == Consent.WitnessLedgerStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWitnessLedger("code-790", title: "title-588")
        item.status = Consent.WitnessLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessLedgerStatus.created) }
    }
}
