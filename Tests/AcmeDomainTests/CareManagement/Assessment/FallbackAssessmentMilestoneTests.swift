@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentMilestoneTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newFallbackAssessmentMilestone("code-366", name: "name-985")
        #expect(item.status == CareManagement.FallbackAssessmentMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newFallbackAssessmentMilestone("code-366", name: "name-985")
        try item.moveTo(CareManagement.FallbackAssessmentMilestoneStatus.approved)
        #expect(item.status == CareManagement.FallbackAssessmentMilestoneStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newFallbackAssessmentMilestone("code-366", name: "name-985")
        item.status = CareManagement.FallbackAssessmentMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackAssessmentMilestoneStatus.proposed) }
    }
}
