@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSummaryTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newGoalSummary("code-648", title: "title-699")
        #expect(item.status == CareManagement.GoalSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newGoalSummary("code-648", title: "title-699")
        try item.moveTo(CareManagement.GoalSummaryStatus.validated)
        #expect(item.status == CareManagement.GoalSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newGoalSummary("code-648", title: "title-699")
        item.status = CareManagement.GoalSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalSummaryStatus.created) }
    }
}
