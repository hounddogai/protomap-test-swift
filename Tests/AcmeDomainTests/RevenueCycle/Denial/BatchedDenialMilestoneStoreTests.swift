@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedDenialMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedDenialMilestoneStore = RevenueCycle.newMemoryBatchedDenialMilestoneStore()
        let item = RevenueCycle.newBatchedDenialMilestone("code-388", name: "name-349")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
