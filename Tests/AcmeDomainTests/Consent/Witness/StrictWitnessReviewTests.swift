@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessReviewTests {
    @Test func startsInDraft() throws {
        let item = Consent.newStrictWitnessReview("code-976", label: "label-764")
        #expect(item.status == Consent.StrictWitnessReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Consent.newStrictWitnessReview("code-976", label: "label-764")
        try item.moveTo(Consent.StrictWitnessReviewStatus.closed)
        #expect(item.status == Consent.StrictWitnessReviewStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newStrictWitnessReview("code-976", label: "label-764")
        item.status = Consent.StrictWitnessReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictWitnessReviewStatus.draft) }
    }
}
