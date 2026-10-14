@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRollupTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newConsentFormRollup("code-195", label: "label-694")
        #expect(item.status == Consent.ConsentFormRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newConsentFormRollup("code-195", label: "label-694")
        try item.moveTo(Consent.ConsentFormRollupStatus.inProgress)
        #expect(item.status == Consent.ConsentFormRollupStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newConsentFormRollup("code-195", label: "label-694")
        item.status = Consent.ConsentFormRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormRollupStatus.planned) }
    }
}
