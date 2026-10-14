@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSlotTests {
    @Test func startsInCreated() throws {
        let item = Consent.newConsentFormSlot("code-199", name: "name-296")
        #expect(item.status == Consent.ConsentFormSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newConsentFormSlot("code-199", name: "name-296")
        try item.moveTo(Consent.ConsentFormSlotStatus.validated)
        #expect(item.status == Consent.ConsentFormSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newConsentFormSlot("code-199", name: "name-296")
        item.status = Consent.ConsentFormSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormSlotStatus.created) }
    }
}
