@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredGoalForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredGoalForecastStore = CareManagement.newMemoryTieredGoalForecastStore()
        let item = CareManagement.newTieredGoalForecast("code-406", name: "name-392")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
