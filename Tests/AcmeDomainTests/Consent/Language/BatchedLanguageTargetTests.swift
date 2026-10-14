@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedLanguageTargetTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newBatchedLanguageTarget("code-639", label: "label-963")
        #expect(item.status == Consent.BatchedLanguageTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newBatchedLanguageTarget("code-639", label: "label-963")
        try item.moveTo(Consent.BatchedLanguageTargetStatus.scheduled)
        #expect(item.status == Consent.BatchedLanguageTargetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newBatchedLanguageTarget("code-639", label: "label-963")
        item.status = Consent.BatchedLanguageTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedLanguageTargetStatus.planned) }
    }
}
