@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedChargeQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedChargeQuotaStore = RevenueCycle.newMemoryBatchedChargeQuotaStore()
        let item = RevenueCycle.newBatchedChargeQuota("code-302", title: "title-308")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
