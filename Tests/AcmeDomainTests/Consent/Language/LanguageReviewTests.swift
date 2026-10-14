@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageReviewTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLanguageReview("code-956", name: "name-771")
        #expect(item.status == Consent.LanguageReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newLanguageReview("code-956", name: "name-771")
        try item.moveTo(Consent.LanguageReviewStatus.granted)
        #expect(item.status == Consent.LanguageReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLanguageReview("code-956", name: "name-771")
        item.status = Consent.LanguageReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageReviewStatus.requested) }
    }
}
