@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentMilestoneTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGlobalAssessmentMilestone("code-472", title: "title-786")
        #expect(item.status == CareManagement.GlobalAssessmentMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newGlobalAssessmentMilestone("code-472", title: "title-786")
        try item.moveTo(CareManagement.GlobalAssessmentMilestoneStatus.inReview)
        #expect(item.status == CareManagement.GlobalAssessmentMilestoneStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGlobalAssessmentMilestone("code-472", title: "title-786")
        item.status = CareManagement.GlobalAssessmentMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalAssessmentMilestoneStatus.`open`) }
    }
}
