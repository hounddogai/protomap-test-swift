@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalClaimTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalClaim("code-513", name: "name-184")
        #expect(item.status == CareManagement.GoalClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newGoalClaim("code-513", name: "name-184")
        try item.moveTo(CareManagement.GoalClaimStatus.reopened)
        #expect(item.status == CareManagement.GoalClaimStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalClaim("code-513", name: "name-184")
        item.status = CareManagement.GoalClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalClaimStatus.`open`) }
    }
}
