@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionReviewTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newRegionalSubstitutionReview("code-821", name: "name-30")
        #expect(item.status == Pharmacy.RegionalSubstitutionReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newRegionalSubstitutionReview("code-821", name: "name-30")
        try item.moveTo(Pharmacy.RegionalSubstitutionReviewStatus.suspended)
        #expect(item.status == Pharmacy.RegionalSubstitutionReviewStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newRegionalSubstitutionReview("code-821", name: "name-30")
        item.status = Pharmacy.RegionalSubstitutionReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalSubstitutionReviewStatus.draft) }
    }
}
