@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictConsentFormWindowTests {
    @Test func startsInCreated() throws {
        let item = Consent.newStrictConsentFormWindow("code-846", name: "name-583")
        #expect(item.status == Consent.StrictConsentFormWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newStrictConsentFormWindow("code-846", name: "name-583")
        try item.moveTo(Consent.StrictConsentFormWindowStatus.published)
        #expect(item.status == Consent.StrictConsentFormWindowStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newStrictConsentFormWindow("code-846", name: "name-583")
        item.status = Consent.StrictConsentFormWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictConsentFormWindowStatus.created) }
    }
}
