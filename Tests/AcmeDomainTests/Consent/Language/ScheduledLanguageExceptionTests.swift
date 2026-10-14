@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageExceptionTests {
    @Test func startsInIdle() throws {
        let item = Consent.newScheduledLanguageException("code-737", label: "label-117")
        #expect(item.status == Consent.ScheduledLanguageExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Consent.newScheduledLanguageException("code-737", label: "label-117")
        try item.moveTo(Consent.ScheduledLanguageExceptionStatus.stopped)
        #expect(item.status == Consent.ScheduledLanguageExceptionStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newScheduledLanguageException("code-737", label: "label-117")
        item.status = Consent.ScheduledLanguageExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledLanguageExceptionStatus.idle) }
    }
}
