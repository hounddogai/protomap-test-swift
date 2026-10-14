@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedGoalBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedGoalBaselineStore = CareManagement.newMemoryBatchedGoalBaselineStore()
        let item = CareManagement.newBatchedGoalBaseline("code-237", title: "title-303")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
