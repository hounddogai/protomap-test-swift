@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionLedgerTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newSubstitutionLedger("code-465", label: "label-292")
        #expect(item.status == Pharmacy.SubstitutionLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newSubstitutionLedger("code-465", label: "label-292")
        try item.moveTo(Pharmacy.SubstitutionLedgerStatus.inReview)
        #expect(item.status == Pharmacy.SubstitutionLedgerStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newSubstitutionLedger("code-465", label: "label-292")
        item.status = Pharmacy.SubstitutionLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionLedgerStatus.`open`) }
    }
}
