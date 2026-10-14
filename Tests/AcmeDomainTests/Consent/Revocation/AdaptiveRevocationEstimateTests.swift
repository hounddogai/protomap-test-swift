@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationEstimateTests {
    @Test func startsInOpen() throws {
        let item = Consent.newAdaptiveRevocationEstimate("code-855", title: "title-245")
        #expect(item.status == Consent.AdaptiveRevocationEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newAdaptiveRevocationEstimate("code-855", title: "title-245")
        try item.moveTo(Consent.AdaptiveRevocationEstimateStatus.inReview)
        #expect(item.status == Consent.AdaptiveRevocationEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newAdaptiveRevocationEstimate("code-855", title: "title-245")
        item.status = Consent.AdaptiveRevocationEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveRevocationEstimateStatus.`open`) }
    }
}
