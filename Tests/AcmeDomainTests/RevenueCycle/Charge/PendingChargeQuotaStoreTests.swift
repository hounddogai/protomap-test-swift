@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingChargeQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingChargeQuotaStore = RevenueCycle.newMemoryPendingChargeQuotaStore()
        let item = RevenueCycle.newPendingChargeQuota("code-80", title: "title-637")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
