@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormReviewTests {
    @Test func startsInIdle() throws {
        let item = Consent.newConsentFormReview("code-430", label: "label-3")
        #expect(item.status == Consent.ConsentFormReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newConsentFormReview("code-430", label: "label-3")
        try item.moveTo(Consent.ConsentFormReviewStatus.warming)
        #expect(item.status == Consent.ConsentFormReviewStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newConsentFormReview("code-430", label: "label-3")
        item.status = Consent.ConsentFormReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormReviewStatus.idle) }
    }
}
