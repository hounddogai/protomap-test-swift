@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAllocationTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newSubstitutionAllocation("code-566", label: "label-996")
        #expect(item.status == Pharmacy.SubstitutionAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newSubstitutionAllocation("code-566", label: "label-996")
        try item.moveTo(Pharmacy.SubstitutionAllocationStatus.inReview)
        #expect(item.status == Pharmacy.SubstitutionAllocationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newSubstitutionAllocation("code-566", label: "label-996")
        item.status = Pharmacy.SubstitutionAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionAllocationStatus.`open`) }
    }
}
