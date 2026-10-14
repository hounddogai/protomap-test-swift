@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedDenialPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedDenialPolicyStore = RevenueCycle.newMemoryBatchedDenialPolicyStore()
        let item = RevenueCycle.newBatchedDenialPolicy("code-117", title: "title-693")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
