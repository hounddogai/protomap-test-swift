@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalGroupStore = CareManagement.newMemoryGoalGroupStore()
        let item = CareManagement.newGoalGroup("code-316", label: "label-304")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
