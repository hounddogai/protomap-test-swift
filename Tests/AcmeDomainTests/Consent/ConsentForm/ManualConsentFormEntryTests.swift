@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormEntryTests {
    @Test func startsInRequested() throws {
        let item = Consent.newManualConsentFormEntry("code-876", name: "name-93")
        #expect(item.status == Consent.ManualConsentFormEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newManualConsentFormEntry("code-876", name: "name-93")
        try item.moveTo(Consent.ManualConsentFormEntryStatus.expired)
        #expect(item.status == Consent.ManualConsentFormEntryStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newManualConsentFormEntry("code-876", name: "name-93")
        item.status = Consent.ManualConsentFormEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualConsentFormEntryStatus.requested) }
    }
}
