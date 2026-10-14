@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageThresholdTests {
    @Test func startsInNew() throws {
        let item = Consent.newLanguageThreshold("code-629", label: "label-174")
        #expect(item.status == Consent.LanguageThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newLanguageThreshold("code-629", label: "label-174")
        try item.moveTo(Consent.LanguageThresholdStatus.running)
        #expect(item.status == Consent.LanguageThresholdStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLanguageThreshold("code-629", label: "label-174")
        item.status = Consent.LanguageThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageThresholdStatus.new) }
    }
}
