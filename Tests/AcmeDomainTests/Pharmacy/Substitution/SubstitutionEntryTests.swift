@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionEntryTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newSubstitutionEntry("code-576", label: "label-193")
        #expect(item.status == Pharmacy.SubstitutionEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newSubstitutionEntry("code-576", label: "label-193")
        try item.moveTo(Pharmacy.SubstitutionEntryStatus.reopened)
        #expect(item.status == Pharmacy.SubstitutionEntryStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newSubstitutionEntry("code-576", label: "label-193")
        item.status = Pharmacy.SubstitutionEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionEntryStatus.`open`) }
    }
}
