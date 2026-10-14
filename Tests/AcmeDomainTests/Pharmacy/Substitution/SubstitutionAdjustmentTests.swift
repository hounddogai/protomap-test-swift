@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newSubstitutionAdjustment("code-702", label: "label-946")
        #expect(item.status == Pharmacy.SubstitutionAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newSubstitutionAdjustment("code-702", label: "label-946")
        try item.moveTo(Pharmacy.SubstitutionAdjustmentStatus.pending)
        #expect(item.status == Pharmacy.SubstitutionAdjustmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newSubstitutionAdjustment("code-702", label: "label-946")
        item.status = Pharmacy.SubstitutionAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionAdjustmentStatus.draft) }
    }
}
