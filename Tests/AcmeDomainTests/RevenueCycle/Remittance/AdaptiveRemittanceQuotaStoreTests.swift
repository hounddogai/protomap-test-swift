@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveRemittanceQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveRemittanceQuotaStore = RevenueCycle.newMemoryAdaptiveRemittanceQuotaStore()
        let item = RevenueCycle.newAdaptiveRemittanceQuota("code-890", label: "label-588")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
