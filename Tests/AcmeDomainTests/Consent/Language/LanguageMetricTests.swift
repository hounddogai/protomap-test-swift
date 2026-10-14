@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageMetricTests {
    @Test func startsInCreated() throws {
        let item = Consent.newLanguageMetric("code-347", name: "name-345")
        #expect(item.status == Consent.LanguageMetricStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newLanguageMetric("code-347", name: "name-345")
        try item.moveTo(Consent.LanguageMetricStatus.published)
        #expect(item.status == Consent.LanguageMetricStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newLanguageMetric("code-347", name: "name-345")
        item.status = Consent.LanguageMetricStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageMetricStatus.created) }
    }
}
