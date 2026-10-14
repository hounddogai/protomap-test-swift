@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Labs.newWeightedSpecimenMilestone("code-7", name: "name-826")
        #expect(item.status == Labs.WeightedSpecimenMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newWeightedSpecimenMilestone("code-7", name: "name-826")
        try item.moveTo(Labs.WeightedSpecimenMilestoneStatus.ready)
        #expect(item.status == Labs.WeightedSpecimenMilestoneStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newWeightedSpecimenMilestone("code-7", name: "name-826")
        item.status = Labs.WeightedSpecimenMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedSpecimenMilestoneStatus.idle) }
    }
}
