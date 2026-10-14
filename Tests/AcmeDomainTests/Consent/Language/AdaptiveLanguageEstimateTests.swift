@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageEstimateTests {
    @Test func startsInOpen() throws {
        let item = Consent.newAdaptiveLanguageEstimate("code-830", label: "label-902")
        #expect(item.status == Consent.AdaptiveLanguageEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newAdaptiveLanguageEstimate("code-830", label: "label-902")
        try item.moveTo(Consent.AdaptiveLanguageEstimateStatus.resolved)
        #expect(item.status == Consent.AdaptiveLanguageEstimateStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newAdaptiveLanguageEstimate("code-830", label: "label-902")
        item.status = Consent.AdaptiveLanguageEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveLanguageEstimateStatus.`open`) }
    }
}
