@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormEntryTests {
    @Test func startsInIdle() throws {
        let item = Consent.newConsentFormEntry("code-272", label: "label-87")
        #expect(item.status == Consent.ConsentFormEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newConsentFormEntry("code-272", label: "label-87")
        try item.moveTo(Consent.ConsentFormEntryStatus.ready)
        #expect(item.status == Consent.ConsentFormEntryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newConsentFormEntry("code-272", label: "label-87")
        item.status = Consent.ConsentFormEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormEntryStatus.idle) }
    }
}
