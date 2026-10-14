@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormExceptionTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newConsentFormException("code-301", name: "name-97")
        #expect(item.status == Consent.ConsentFormExceptionStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newConsentFormException("code-301", name: "name-97")
        try item.moveTo(Consent.ConsentFormExceptionStatus.inProgress)
        #expect(item.status == Consent.ConsentFormExceptionStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newConsentFormException("code-301", name: "name-97")
        item.status = Consent.ConsentFormExceptionStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormExceptionStatus.planned) }
    }
}
