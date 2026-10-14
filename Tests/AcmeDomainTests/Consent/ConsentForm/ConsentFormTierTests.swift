@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormTierTests {
    @Test func startsInCreated() throws {
        let item = Consent.newConsentFormTier("code-79", title: "title-443")
        #expect(item.status == Consent.ConsentFormTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newConsentFormTier("code-79", title: "title-443")
        try item.moveTo(Consent.ConsentFormTierStatus.validated)
        #expect(item.status == Consent.ConsentFormTierStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newConsentFormTier("code-79", title: "title-443")
        item.status = Consent.ConsentFormTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormTierStatus.created) }
    }
}
