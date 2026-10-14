@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalLedgerTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalLedger("code-73", name: "name-298")
        #expect(item.status == CareManagement.GoalLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newGoalLedger("code-73", name: "name-298")
        try item.moveTo(CareManagement.GoalLedgerStatus.inReview)
        #expect(item.status == CareManagement.GoalLedgerStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalLedger("code-73", name: "name-298")
        item.status = CareManagement.GoalLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalLedgerStatus.`open`) }
    }
}
