@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationReviewTests {
    @Test func startsInRequested() throws {
        let item = Consent.newScheduledRevocationReview("code-100", name: "name-528")
        #expect(item.status == Consent.ScheduledRevocationReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newScheduledRevocationReview("code-100", name: "name-528")
        try item.moveTo(Consent.ScheduledRevocationReviewStatus.revoked)
        #expect(item.status == Consent.ScheduledRevocationReviewStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newScheduledRevocationReview("code-100", name: "name-528")
        item.status = Consent.ScheduledRevocationReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledRevocationReviewStatus.requested) }
    }
}
