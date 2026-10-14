@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageScoreTests {
    @Test func startsInCreated() throws {
        let item = Consent.newLenientLanguageScore("code-40", name: "name-530")
        #expect(item.status == Consent.LenientLanguageScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newLenientLanguageScore("code-40", name: "name-530")
        try item.moveTo(Consent.LenientLanguageScoreStatus.validated)
        #expect(item.status == Consent.LenientLanguageScoreStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newLenientLanguageScore("code-40", name: "name-530")
        item.status = Consent.LenientLanguageScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientLanguageScoreStatus.created) }
    }
}
