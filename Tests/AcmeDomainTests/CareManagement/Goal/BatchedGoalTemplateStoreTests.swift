@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedGoalTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedGoalTemplateStore = CareManagement.newMemoryBatchedGoalTemplateStore()
        let item = CareManagement.newBatchedGoalTemplate("code-494", name: "name-103")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
