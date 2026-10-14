@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormReviewTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRollingConsentFormReview("code-581", title: "title-665")
        #expect(item.status == Consent.RollingConsentFormReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newRollingConsentFormReview("code-581", title: "title-665")
        try item.moveTo(Consent.RollingConsentFormReviewStatus.published)
        #expect(item.status == Consent.RollingConsentFormReviewStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRollingConsentFormReview("code-581", title: "title-665")
        item.status = Consent.RollingConsentFormReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingConsentFormReviewStatus.created) }
    }
}
