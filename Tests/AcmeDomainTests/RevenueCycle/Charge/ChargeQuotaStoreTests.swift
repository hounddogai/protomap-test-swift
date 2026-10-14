@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeQuotaStore = RevenueCycle.newMemoryChargeQuotaStore()
        let item = RevenueCycle.newChargeQuota("code-771", title: "title-55")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
