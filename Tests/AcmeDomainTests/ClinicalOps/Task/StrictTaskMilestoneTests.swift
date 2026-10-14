@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskMilestoneTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newStrictTaskMilestone("code-424", title: "title-628")
        #expect(item.status == ClinicalOps.StrictTaskMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newStrictTaskMilestone("code-424", title: "title-628")
        try item.moveTo(ClinicalOps.StrictTaskMilestoneStatus.ready)
        #expect(item.status == ClinicalOps.StrictTaskMilestoneStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newStrictTaskMilestone("code-424", title: "title-628")
        item.status = ClinicalOps.StrictTaskMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictTaskMilestoneStatus.idle) }
    }
}
