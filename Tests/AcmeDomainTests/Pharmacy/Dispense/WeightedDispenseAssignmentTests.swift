@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newWeightedDispenseAssignment("code-688", label: "label-30")
        #expect(item.status == Pharmacy.WeightedDispenseAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newWeightedDispenseAssignment("code-688", label: "label-30")
        try item.moveTo(Pharmacy.WeightedDispenseAssignmentStatus.scheduled)
        #expect(item.status == Pharmacy.WeightedDispenseAssignmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newWeightedDispenseAssignment("code-688", label: "label-30")
        item.status = Pharmacy.WeightedDispenseAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedDispenseAssignmentStatus.planned) }
    }
}
