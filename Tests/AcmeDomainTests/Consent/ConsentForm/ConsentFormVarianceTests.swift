@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormVarianceTests {
    @Test func startsInCreated() throws {
        let item = Consent.newConsentFormVariance("code-851", label: "label-196")
        #expect(item.status == Consent.ConsentFormVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newConsentFormVariance("code-851", label: "label-196")
        try item.moveTo(Consent.ConsentFormVarianceStatus.published)
        #expect(item.status == Consent.ConsentFormVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newConsentFormVariance("code-851", label: "label-196")
        item.status = Consent.ConsentFormVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormVarianceStatus.created) }
    }
}
