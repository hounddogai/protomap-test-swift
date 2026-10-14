@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyEntryTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newWeightedFormularyEntry("code-329", title: "title-224")
        #expect(item.status == Pharmacy.WeightedFormularyEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newWeightedFormularyEntry("code-329", title: "title-224")
        try item.moveTo(Pharmacy.WeightedFormularyEntryStatus.rejected)
        #expect(item.status == Pharmacy.WeightedFormularyEntryStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newWeightedFormularyEntry("code-329", title: "title-224")
        item.status = Pharmacy.WeightedFormularyEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedFormularyEntryStatus.proposed) }
    }
}
