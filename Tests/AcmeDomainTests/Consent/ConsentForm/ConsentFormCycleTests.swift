@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormCycleTests {
    @Test func startsInDraft() throws {
        let item = Consent.newConsentFormCycle("code-867", name: "name-360")
        #expect(item.status == Consent.ConsentFormCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newConsentFormCycle("code-867", name: "name-360")
        try item.moveTo(Consent.ConsentFormCycleStatus.suspended)
        #expect(item.status == Consent.ConsentFormCycleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newConsentFormCycle("code-867", name: "name-360")
        item.status = Consent.ConsentFormCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormCycleStatus.draft) }
    }
}
