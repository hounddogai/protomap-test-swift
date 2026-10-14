@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalForecastStore = CareManagement.newMemoryGoalForecastStore()
        let item = CareManagement.newGoalForecast("code-330", title: "title-658")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
