@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalPlanStore = CareManagement.newMemoryGoalPlanStore()
        let item = CareManagement.newGoalPlan("code-84", name: "name-761")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
