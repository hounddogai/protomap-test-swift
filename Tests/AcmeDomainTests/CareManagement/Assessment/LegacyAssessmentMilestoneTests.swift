@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyAssessmentMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newLegacyAssessmentMilestone("code-329", name: "name-855")
        #expect(item.status == CareManagement.LegacyAssessmentMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newLegacyAssessmentMilestone("code-329", name: "name-855")
        try item.moveTo(CareManagement.LegacyAssessmentMilestoneStatus.inProgress)
        #expect(item.status == CareManagement.LegacyAssessmentMilestoneStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newLegacyAssessmentMilestone("code-329", name: "name-855")
        item.status = CareManagement.LegacyAssessmentMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyAssessmentMilestoneStatus.planned) }
    }
}
