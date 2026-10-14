@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalVarianceTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newGoalVariance("code-949", label: "label-718")
        #expect(item.status == CareManagement.GoalVarianceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = CareManagement.newGoalVariance("code-949", label: "label-718")
        try item.moveTo(CareManagement.GoalVarianceStatus.stopped)
        #expect(item.status == CareManagement.GoalVarianceStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newGoalVariance("code-949", label: "label-718")
        item.status = CareManagement.GoalVarianceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalVarianceStatus.idle) }
    }
}
