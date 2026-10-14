@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalMetricStore = CareManagement.newMemoryGoalMetricStore()
        let item = CareManagement.newGoalMetric("code-341", name: "name-140")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
