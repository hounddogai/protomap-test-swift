@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormReviewTests {
    @Test func startsInOpen() throws {
        let item = Consent.newScheduledConsentFormReview("code-205", name: "name-823")
        #expect(item.status == Consent.ScheduledConsentFormReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newScheduledConsentFormReview("code-205", name: "name-823")
        try item.moveTo(Consent.ScheduledConsentFormReviewStatus.resolved)
        #expect(item.status == Consent.ScheduledConsentFormReviewStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newScheduledConsentFormReview("code-205", name: "name-823")
        item.status = Consent.ScheduledConsentFormReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledConsentFormReviewStatus.`open`) }
    }
}
