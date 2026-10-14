@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionRecordTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRegionalSubstitutionRecord("code-468", title: "title-534")
        #expect(item.status == Pharmacy.RegionalSubstitutionRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newRegionalSubstitutionRecord("code-468", title: "title-534")
        try item.moveTo(Pharmacy.RegionalSubstitutionRecordStatus.inReview)
        #expect(item.status == Pharmacy.RegionalSubstitutionRecordStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRegionalSubstitutionRecord("code-468", title: "title-534")
        item.status = Pharmacy.RegionalSubstitutionRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalSubstitutionRecordStatus.`open`) }
    }
}
