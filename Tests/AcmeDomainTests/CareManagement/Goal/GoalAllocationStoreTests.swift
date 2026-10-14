@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalAllocationStore = CareManagement.newMemoryGoalAllocationStore()
        let item = CareManagement.newGoalAllocation("code-674", label: "label-360")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
