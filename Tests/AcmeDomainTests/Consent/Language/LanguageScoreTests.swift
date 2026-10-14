@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageScoreTests {
    @Test func startsInNew() throws {
        let item = Consent.newLanguageScore("code-601", name: "name-852")
        #expect(item.status == Consent.LanguageScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newLanguageScore("code-601", name: "name-852")
        try item.moveTo(Consent.LanguageScoreStatus.running)
        #expect(item.status == Consent.LanguageScoreStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLanguageScore("code-601", name: "name-852")
        item.status = Consent.LanguageScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageScoreStatus.new) }
    }
}
