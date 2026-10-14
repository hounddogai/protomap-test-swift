@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormWindowTests {
    @Test func startsInIdle() throws {
        let item = Consent.newConsentFormWindow("code-978", label: "label-40")
        #expect(item.status == Consent.ConsentFormWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newConsentFormWindow("code-978", label: "label-40")
        try item.moveTo(Consent.ConsentFormWindowStatus.ready)
        #expect(item.status == Consent.ConsentFormWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newConsentFormWindow("code-978", label: "label-40")
        item.status = Consent.ConsentFormWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormWindowStatus.idle) }
    }
}
