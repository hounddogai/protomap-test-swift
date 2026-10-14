@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskMilestoneTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newTieredTaskMilestone("code-57", name: "name-112")
        #expect(item.status == ClinicalOps.TieredTaskMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newTieredTaskMilestone("code-57", name: "name-112")
        try item.moveTo(ClinicalOps.TieredTaskMilestoneStatus.reopened)
        #expect(item.status == ClinicalOps.TieredTaskMilestoneStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newTieredTaskMilestone("code-57", name: "name-112")
        item.status = ClinicalOps.TieredTaskMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredTaskMilestoneStatus.`open`) }
    }
}
