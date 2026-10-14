@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalRequestStore = CareManagement.newMemoryGoalRequestStore()
        let item = CareManagement.newGoalRequest("code-67", label: "label-504")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
