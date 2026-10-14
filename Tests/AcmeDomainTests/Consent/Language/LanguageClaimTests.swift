@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageClaimTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLanguageClaim("code-422", label: "label-86")
        #expect(item.status == Consent.LanguageClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newLanguageClaim("code-422", label: "label-86")
        try item.moveTo(Consent.LanguageClaimStatus.rejected)
        #expect(item.status == Consent.LanguageClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLanguageClaim("code-422", label: "label-86")
        item.status = Consent.LanguageClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageClaimStatus.proposed) }
    }
}
