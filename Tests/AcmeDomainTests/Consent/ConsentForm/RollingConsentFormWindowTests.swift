@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormWindowTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRollingConsentFormWindow("code-122", title: "title-208")
        #expect(item.status == Consent.RollingConsentFormWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newRollingConsentFormWindow("code-122", title: "title-208")
        try item.moveTo(Consent.RollingConsentFormWindowStatus.inProgress)
        #expect(item.status == Consent.RollingConsentFormWindowStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRollingConsentFormWindow("code-122", title: "title-208")
        item.status = Consent.RollingConsentFormWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingConsentFormWindowStatus.planned) }
    }
}
