@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageQuotaTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLanguageQuota("code-424", title: "title-392")
        #expect(item.status == Consent.LanguageQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newLanguageQuota("code-424", title: "title-392")
        try item.moveTo(Consent.LanguageQuotaStatus.rejected)
        #expect(item.status == Consent.LanguageQuotaStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLanguageQuota("code-424", title: "title-392")
        item.status = Consent.LanguageQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageQuotaStatus.proposed) }
    }
}
