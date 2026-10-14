@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageClaimTests {
    @Test func startsInOpen() throws {
        let item = Consent.newAdaptiveLanguageClaim("code-438", label: "label-591")
        #expect(item.status == Consent.AdaptiveLanguageClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newAdaptiveLanguageClaim("code-438", label: "label-591")
        try item.moveTo(Consent.AdaptiveLanguageClaimStatus.resolved)
        #expect(item.status == Consent.AdaptiveLanguageClaimStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newAdaptiveLanguageClaim("code-438", label: "label-591")
        item.status = Consent.AdaptiveLanguageClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveLanguageClaimStatus.`open`) }
    }
}
