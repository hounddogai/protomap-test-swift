@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedConsentFormLedgerTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWeightedConsentFormLedger("code-745", name: "name-590")
        #expect(item.status == Consent.WeightedConsentFormLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newWeightedConsentFormLedger("code-745", name: "name-590")
        try item.moveTo(Consent.WeightedConsentFormLedgerStatus.suspended)
        #expect(item.status == Consent.WeightedConsentFormLedgerStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWeightedConsentFormLedger("code-745", name: "name-590")
        item.status = Consent.WeightedConsentFormLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedConsentFormLedgerStatus.draft) }
    }
}
