@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRollupTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newSubstitutionRollup("code-777", name: "name-325")
        #expect(item.status == Pharmacy.SubstitutionRollupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newSubstitutionRollup("code-777", name: "name-325")
        try item.moveTo(Pharmacy.SubstitutionRollupStatus.rejected)
        #expect(item.status == Pharmacy.SubstitutionRollupStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newSubstitutionRollup("code-777", name: "name-325")
        item.status = Pharmacy.SubstitutionRollupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionRollupStatus.proposed) }
    }
}
