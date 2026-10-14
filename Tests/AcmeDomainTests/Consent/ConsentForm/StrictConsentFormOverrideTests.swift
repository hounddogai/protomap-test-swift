@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictConsentFormOverrideTests {
    @Test func startsInNew() throws {
        let item = Consent.newStrictConsentFormOverride("code-600", name: "name-967")
        #expect(item.status == Consent.StrictConsentFormOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newStrictConsentFormOverride("code-600", name: "name-967")
        try item.moveTo(Consent.StrictConsentFormOverrideStatus.done)
        #expect(item.status == Consent.StrictConsentFormOverrideStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newStrictConsentFormOverride("code-600", name: "name-967")
        item.status = Consent.StrictConsentFormOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictConsentFormOverrideStatus.new) }
    }
}
