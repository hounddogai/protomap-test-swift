@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormReviewTests {
    @Test func startsInCreated() throws {
        let item = Consent.newAdaptiveConsentFormReview("code-815", name: "name-450")
        #expect(item.status == Consent.AdaptiveConsentFormReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newAdaptiveConsentFormReview("code-815", name: "name-450")
        try item.moveTo(Consent.AdaptiveConsentFormReviewStatus.published)
        #expect(item.status == Consent.AdaptiveConsentFormReviewStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newAdaptiveConsentFormReview("code-815", name: "name-450")
        item.status = Consent.AdaptiveConsentFormReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveConsentFormReviewStatus.created) }
    }
}
