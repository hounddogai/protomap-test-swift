@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureReviewTests {
    @Test func startsInProposed() throws {
        let item = Consent.newDisclosureReview("code-189", label: "label-208")
        #expect(item.status == Consent.DisclosureReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Consent.newDisclosureReview("code-189", label: "label-208")
        try item.moveTo(Consent.DisclosureReviewStatus.withdrawn)
        #expect(item.status == Consent.DisclosureReviewStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newDisclosureReview("code-189", label: "label-208")
        item.status = Consent.DisclosureReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureReviewStatus.proposed) }
    }
}
