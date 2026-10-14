@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalMappingStore = CareManagement.newMemoryGoalMappingStore()
        let item = CareManagement.newGoalMapping("code-624", label: "label-922")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
