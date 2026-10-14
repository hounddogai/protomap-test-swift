@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyGroupTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newWeightedFormularyGroup("code-709", label: "label-841")
        #expect(item.status == Pharmacy.WeightedFormularyGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newWeightedFormularyGroup("code-709", label: "label-841")
        try item.moveTo(Pharmacy.WeightedFormularyGroupStatus.pending)
        #expect(item.status == Pharmacy.WeightedFormularyGroupStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newWeightedFormularyGroup("code-709", label: "label-841")
        item.status = Pharmacy.WeightedFormularyGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedFormularyGroupStatus.draft) }
    }
}
