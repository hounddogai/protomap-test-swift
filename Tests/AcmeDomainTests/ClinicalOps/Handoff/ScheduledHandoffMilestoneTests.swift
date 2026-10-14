@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffMilestoneTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newScheduledHandoffMilestone("code-324", label: "label-671")
        #expect(item.status == ClinicalOps.ScheduledHandoffMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newScheduledHandoffMilestone("code-324", label: "label-671")
        try item.moveTo(ClinicalOps.ScheduledHandoffMilestoneStatus.warming)
        #expect(item.status == ClinicalOps.ScheduledHandoffMilestoneStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newScheduledHandoffMilestone("code-324", label: "label-671")
        item.status = ClinicalOps.ScheduledHandoffMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledHandoffMilestoneStatus.idle) }
    }
}
