@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapMilestoneTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapMilestone("code-859", name: "name-134")
        #expect(item.status == CareManagement.CareGapMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newCareGapMilestone("code-859", name: "name-134")
        try item.moveTo(CareManagement.CareGapMilestoneStatus.inReview)
        #expect(item.status == CareManagement.CareGapMilestoneStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapMilestone("code-859", name: "name-134")
        item.status = CareManagement.CareGapMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapMilestoneStatus.`open`) }
    }
}
