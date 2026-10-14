@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationReviewTests {
    @Test func startsInDraft() throws {
        let item = Consent.newRevocationReview("code-941", title: "title-478")
        #expect(item.status == Consent.RevocationReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newRevocationReview("code-941", title: "title-478")
        try item.moveTo(Consent.RevocationReviewStatus.active)
        #expect(item.status == Consent.RevocationReviewStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newRevocationReview("code-941", title: "title-478")
        item.status = Consent.RevocationReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationReviewStatus.draft) }
    }
}
