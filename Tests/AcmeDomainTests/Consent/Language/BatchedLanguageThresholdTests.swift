@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedLanguageThresholdTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newBatchedLanguageThreshold("code-603", label: "label-531")
        #expect(item.status == Consent.BatchedLanguageThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newBatchedLanguageThreshold("code-603", label: "label-531")
        try item.moveTo(Consent.BatchedLanguageThresholdStatus.completed)
        #expect(item.status == Consent.BatchedLanguageThresholdStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newBatchedLanguageThreshold("code-603", label: "label-531")
        item.status = Consent.BatchedLanguageThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedLanguageThresholdStatus.planned) }
    }
}
