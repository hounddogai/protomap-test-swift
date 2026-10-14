@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalVarianceStore = CareManagement.newMemoryGoalVarianceStore()
        let item = CareManagement.newGoalVariance("code-949", label: "label-718")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
