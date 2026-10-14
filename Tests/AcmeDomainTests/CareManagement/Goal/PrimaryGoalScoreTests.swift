@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryGoalScoreTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newPrimaryGoalScore("code-113", title: "title-235")
        #expect(item.status == CareManagement.PrimaryGoalScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newPrimaryGoalScore("code-113", title: "title-235")
        try item.moveTo(CareManagement.PrimaryGoalScoreStatus.suspended)
        #expect(item.status == CareManagement.PrimaryGoalScoreStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newPrimaryGoalScore("code-113", title: "title-235")
        item.status = CareManagement.PrimaryGoalScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryGoalScoreStatus.draft) }
    }
}
