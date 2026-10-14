@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalMappingTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalMapping("code-624", label: "label-922")
        #expect(item.status == CareManagement.GoalMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newGoalMapping("code-624", label: "label-922")
        try item.moveTo(CareManagement.GoalMappingStatus.inReview)
        #expect(item.status == CareManagement.GoalMappingStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalMapping("code-624", label: "label-922")
        item.status = CareManagement.GoalMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalMappingStatus.`open`) }
    }
}
