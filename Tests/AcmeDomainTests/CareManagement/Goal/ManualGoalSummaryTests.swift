@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualGoalSummaryTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newManualGoalSummary("code-713", label: "label-565")
        #expect(item.status == CareManagement.ManualGoalSummaryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newManualGoalSummary("code-713", label: "label-565")
        try item.moveTo(CareManagement.ManualGoalSummaryStatus.rejected)
        #expect(item.status == CareManagement.ManualGoalSummaryStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newManualGoalSummary("code-713", label: "label-565")
        item.status = CareManagement.ManualGoalSummaryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualGoalSummaryStatus.proposed) }
    }
}
