@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedGoalCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedGoalCycleStore = CareManagement.newMemoryWeightedGoalCycleStore()
        let item = CareManagement.newWeightedGoalCycle("code-261", title: "title-945")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
