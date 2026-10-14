@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredGoalForecastTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newTieredGoalForecast("code-406", name: "name-392")
        #expect(item.status == CareManagement.TieredGoalForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newTieredGoalForecast("code-406", name: "name-392")
        try item.moveTo(CareManagement.TieredGoalForecastStatus.published)
        #expect(item.status == CareManagement.TieredGoalForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newTieredGoalForecast("code-406", name: "name-392")
        item.status = CareManagement.TieredGoalForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredGoalForecastStatus.created) }
    }
}
