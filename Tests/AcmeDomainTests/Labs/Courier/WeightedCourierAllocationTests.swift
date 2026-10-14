@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newWeightedCourierAllocation("code-357", name: "name-259")
        #expect(item.status == Labs.WeightedCourierAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newWeightedCourierAllocation("code-357", name: "name-259")
        try item.moveTo(Labs.WeightedCourierAllocationStatus.scheduled)
        #expect(item.status == Labs.WeightedCourierAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newWeightedCourierAllocation("code-357", name: "name-259")
        item.status = Labs.WeightedCourierAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedCourierAllocationStatus.planned) }
    }
}
