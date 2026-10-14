@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormLedgerTests {
    @Test func startsInProposed() throws {
        let item = Consent.newConsentFormLedger("code-836", title: "title-284")
        #expect(item.status == Consent.ConsentFormLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newConsentFormLedger("code-836", title: "title-284")
        try item.moveTo(Consent.ConsentFormLedgerStatus.approved)
        #expect(item.status == Consent.ConsentFormLedgerStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newConsentFormLedger("code-836", title: "title-284")
        item.status = Consent.ConsentFormLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormLedgerStatus.proposed) }
    }
}
