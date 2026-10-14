@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormReviewTests {
    @Test func startsInNew() throws {
        let item = Consent.newPrimaryConsentFormReview("code-466", title: "title-184")
        #expect(item.status == Consent.PrimaryConsentFormReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newPrimaryConsentFormReview("code-466", title: "title-184")
        try item.moveTo(Consent.PrimaryConsentFormReviewStatus.queued)
        #expect(item.status == Consent.PrimaryConsentFormReviewStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newPrimaryConsentFormReview("code-466", title: "title-184")
        item.status = Consent.PrimaryConsentFormReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryConsentFormReviewStatus.new) }
    }
}
