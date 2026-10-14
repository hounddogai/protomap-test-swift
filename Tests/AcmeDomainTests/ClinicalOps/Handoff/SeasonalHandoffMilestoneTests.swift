@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalHandoffMilestoneTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newSeasonalHandoffMilestone("code-208", label: "label-666")
        #expect(item.status == ClinicalOps.SeasonalHandoffMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newSeasonalHandoffMilestone("code-208", label: "label-666")
        try item.moveTo(ClinicalOps.SeasonalHandoffMilestoneStatus.reopened)
        #expect(item.status == ClinicalOps.SeasonalHandoffMilestoneStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newSeasonalHandoffMilestone("code-208", label: "label-666")
        item.status = ClinicalOps.SeasonalHandoffMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalHandoffMilestoneStatus.`open`) }
    }
}
