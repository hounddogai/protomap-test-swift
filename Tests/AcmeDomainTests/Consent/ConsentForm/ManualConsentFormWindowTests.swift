@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormWindowTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newManualConsentFormWindow("code-979", title: "title-603")
        #expect(item.status == Consent.ManualConsentFormWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newManualConsentFormWindow("code-979", title: "title-603")
        try item.moveTo(Consent.ManualConsentFormWindowStatus.completed)
        #expect(item.status == Consent.ManualConsentFormWindowStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newManualConsentFormWindow("code-979", title: "title-603")
        item.status = Consent.ManualConsentFormWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualConsentFormWindowStatus.planned) }
    }
}
