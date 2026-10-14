@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageBaselineTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLanguageBaseline("code-921", name: "name-870")
        #expect(item.status == Consent.LanguageBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newLanguageBaseline("code-921", name: "name-870")
        try item.moveTo(Consent.LanguageBaselineStatus.inProgress)
        #expect(item.status == Consent.LanguageBaselineStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLanguageBaseline("code-921", name: "name-870")
        item.status = Consent.LanguageBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageBaselineStatus.planned) }
    }
}
