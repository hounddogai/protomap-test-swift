@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingLanguageBundleTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRollingLanguageBundle("code-464", label: "label-204")
        #expect(item.status == Consent.RollingLanguageBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newRollingLanguageBundle("code-464", label: "label-204")
        try item.moveTo(Consent.RollingLanguageBundleStatus.validated)
        #expect(item.status == Consent.RollingLanguageBundleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRollingLanguageBundle("code-464", label: "label-204")
        item.status = Consent.RollingLanguageBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingLanguageBundleStatus.created) }
    }
}
