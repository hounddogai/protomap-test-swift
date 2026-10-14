@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormThresholdTests {
    @Test func startsInRequested() throws {
        let item = Consent.newConsentFormThreshold("code-238", title: "title-588")
        #expect(item.status == Consent.ConsentFormThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newConsentFormThreshold("code-238", title: "title-588")
        try item.moveTo(Consent.ConsentFormThresholdStatus.expired)
        #expect(item.status == Consent.ConsentFormThresholdStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newConsentFormThreshold("code-238", title: "title-588")
        item.status = Consent.ConsentFormThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormThresholdStatus.requested) }
    }
}
