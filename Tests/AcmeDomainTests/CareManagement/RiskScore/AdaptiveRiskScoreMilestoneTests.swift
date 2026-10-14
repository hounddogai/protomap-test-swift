@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreMilestoneTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newAdaptiveRiskScoreMilestone("code-361", title: "title-890")
        #expect(item.status == CareManagement.AdaptiveRiskScoreMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newAdaptiveRiskScoreMilestone("code-361", title: "title-890")
        try item.moveTo(CareManagement.AdaptiveRiskScoreMilestoneStatus.validated)
        #expect(item.status == CareManagement.AdaptiveRiskScoreMilestoneStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newAdaptiveRiskScoreMilestone("code-361", title: "title-890")
        item.status = CareManagement.AdaptiveRiskScoreMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveRiskScoreMilestoneStatus.created) }
    }
}
