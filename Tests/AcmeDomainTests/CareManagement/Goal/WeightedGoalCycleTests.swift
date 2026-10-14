@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedGoalCycleTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newWeightedGoalCycle("code-261", title: "title-945")
        #expect(item.status == CareManagement.WeightedGoalCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newWeightedGoalCycle("code-261", title: "title-945")
        try item.moveTo(CareManagement.WeightedGoalCycleStatus.resolved)
        #expect(item.status == CareManagement.WeightedGoalCycleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newWeightedGoalCycle("code-261", title: "title-945")
        item.status = CareManagement.WeightedGoalCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedGoalCycleStatus.`open`) }
    }
}
