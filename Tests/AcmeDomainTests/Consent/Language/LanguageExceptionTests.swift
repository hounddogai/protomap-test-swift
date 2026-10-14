@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageExceptionTests {
    @Test func startsInNew() throws {
        let item = Consent.newLanguageException("code-372", title: "title-76")
        #expect(item.status == Consent.LanguageExceptionStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newLanguageException("code-372", title: "title-76")
        try item.moveTo(Consent.LanguageExceptionStatus.queued)
        #expect(item.status == Consent.LanguageExceptionStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLanguageException("code-372", title: "title-76")
        item.status = Consent.LanguageExceptionStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageExceptionStatus.new) }
    }
}
