@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalCycleTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newRollingGoalCycle("code-329", title: "title-472")
        #expect(item.status == CareManagement.RollingGoalCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newRollingGoalCycle("code-329", title: "title-472")
        try item.moveTo(CareManagement.RollingGoalCycleStatus.archived)
        #expect(item.status == CareManagement.RollingGoalCycleStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newRollingGoalCycle("code-329", title: "title-472")
        item.status = CareManagement.RollingGoalCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingGoalCycleStatus.`open`) }
    }
}
