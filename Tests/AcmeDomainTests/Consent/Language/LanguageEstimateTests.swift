@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageEstimateTests {
    @Test func startsInNew() throws {
        let item = Consent.newLanguageEstimate("code-958", title: "title-184")
        #expect(item.status == Consent.LanguageEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Consent.newLanguageEstimate("code-958", title: "title-184")
        try item.moveTo(Consent.LanguageEstimateStatus.failed)
        #expect(item.status == Consent.LanguageEstimateStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLanguageEstimate("code-958", title: "title-184")
        item.status = Consent.LanguageEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageEstimateStatus.new) }
    }
}
