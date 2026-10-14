@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalTargetStore = CareManagement.newMemoryGoalTargetStore()
        let item = CareManagement.newGoalTarget("code-523", name: "name-851")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
