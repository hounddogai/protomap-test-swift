@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingMilestoneTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newRoundingMilestone("code-584", name: "name-162")
        #expect(item.status == ClinicalOps.RoundingMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newRoundingMilestone("code-584", name: "name-162")
        try item.moveTo(ClinicalOps.RoundingMilestoneStatus.warming)
        #expect(item.status == ClinicalOps.RoundingMilestoneStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newRoundingMilestone("code-584", name: "name-162")
        item.status = ClinicalOps.RoundingMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingMilestoneStatus.idle) }
    }
}
