@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalTemplateTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newBatchedGoalTemplate("code-494", name: "name-103")
        #expect(item.status == CareManagement.BatchedGoalTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newBatchedGoalTemplate("code-494", name: "name-103")
        try item.moveTo(CareManagement.BatchedGoalTemplateStatus.rejected)
        #expect(item.status == CareManagement.BatchedGoalTemplateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newBatchedGoalTemplate("code-494", name: "name-103")
        item.status = CareManagement.BatchedGoalTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedGoalTemplateStatus.proposed) }
    }
}
