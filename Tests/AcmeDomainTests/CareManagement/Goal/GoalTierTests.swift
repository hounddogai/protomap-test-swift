@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTierTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newGoalTier("code-148", label: "label-919")
        #expect(item.status == CareManagement.GoalTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newGoalTier("code-148", label: "label-919")
        try item.moveTo(CareManagement.GoalTierStatus.failed)
        #expect(item.status == CareManagement.GoalTierStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newGoalTier("code-148", label: "label-919")
        item.status = CareManagement.GoalTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalTierStatus.new) }
    }
}
