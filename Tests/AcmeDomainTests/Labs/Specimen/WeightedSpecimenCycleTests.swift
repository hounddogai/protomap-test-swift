@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenCycleTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newWeightedSpecimenCycle("code-298", name: "name-573")
        #expect(item.status == Labs.WeightedSpecimenCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newWeightedSpecimenCycle("code-298", name: "name-573")
        try item.moveTo(Labs.WeightedSpecimenCycleStatus.scheduled)
        #expect(item.status == Labs.WeightedSpecimenCycleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newWeightedSpecimenCycle("code-298", name: "name-573")
        item.status = Labs.WeightedSpecimenCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedSpecimenCycleStatus.planned) }
    }
}
