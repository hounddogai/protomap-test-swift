@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormOverrideTests {
    @Test func startsInOpen() throws {
        let item = Consent.newConsentFormOverride("code-66", label: "label-474")
        #expect(item.status == Consent.ConsentFormOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newConsentFormOverride("code-66", label: "label-474")
        try item.moveTo(Consent.ConsentFormOverrideStatus.reopened)
        #expect(item.status == Consent.ConsentFormOverrideStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newConsentFormOverride("code-66", label: "label-474")
        item.status = Consent.ConsentFormOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormOverrideStatus.`open`) }
    }
}
