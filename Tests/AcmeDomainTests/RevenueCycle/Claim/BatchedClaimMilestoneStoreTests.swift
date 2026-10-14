@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedClaimMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedClaimMilestoneStore = RevenueCycle.newMemoryBatchedClaimMilestoneStore()
        let item = RevenueCycle.newBatchedClaimMilestone("code-199", title: "title-207")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
