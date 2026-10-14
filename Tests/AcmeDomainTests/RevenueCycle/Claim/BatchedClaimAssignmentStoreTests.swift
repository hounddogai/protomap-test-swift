@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedClaimAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedClaimAssignmentStore = RevenueCycle.newMemoryBatchedClaimAssignmentStore()
        let item = RevenueCycle.newBatchedClaimAssignment("code-110", title: "title-76")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
