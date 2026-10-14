@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalDigestTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalDigest("code-634", name: "name-500")
        #expect(item.status == CareManagement.GoalDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newGoalDigest("code-634", name: "name-500")
        try item.moveTo(CareManagement.GoalDigestStatus.reopened)
        #expect(item.status == CareManagement.GoalDigestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalDigest("code-634", name: "name-500")
        item.status = CareManagement.GoalDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalDigestStatus.`open`) }
    }
}
