@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalCycleTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newLegacyGoalCycle("code-738", title: "title-456")
        #expect(item.status == CareManagement.LegacyGoalCycleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newLegacyGoalCycle("code-738", title: "title-456")
        try item.moveTo(CareManagement.LegacyGoalCycleStatus.rejected)
        #expect(item.status == CareManagement.LegacyGoalCycleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newLegacyGoalCycle("code-738", title: "title-456")
        item.status = CareManagement.LegacyGoalCycleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyGoalCycleStatus.proposed) }
    }
}
