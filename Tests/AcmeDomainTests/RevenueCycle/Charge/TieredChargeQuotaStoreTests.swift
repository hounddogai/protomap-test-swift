@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredChargeQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredChargeQuotaStore = RevenueCycle.newMemoryTieredChargeQuotaStore()
        let item = RevenueCycle.newTieredChargeQuota("code-407", label: "label-415")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
