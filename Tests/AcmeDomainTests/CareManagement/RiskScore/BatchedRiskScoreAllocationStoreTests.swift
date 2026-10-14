@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedRiskScoreAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedRiskScoreAllocationStore = CareManagement.newMemoryBatchedRiskScoreAllocationStore()
        let item = CareManagement.newBatchedRiskScoreAllocation("code-958", title: "title-125")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
