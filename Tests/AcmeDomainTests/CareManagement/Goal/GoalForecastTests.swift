@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalForecastTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newGoalForecast("code-330", title: "title-658")
        #expect(item.status == CareManagement.GoalForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newGoalForecast("code-330", title: "title-658")
        try item.moveTo(CareManagement.GoalForecastStatus.published)
        #expect(item.status == CareManagement.GoalForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newGoalForecast("code-330", title: "title-658")
        item.status = CareManagement.GoalForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalForecastStatus.created) }
    }
}
