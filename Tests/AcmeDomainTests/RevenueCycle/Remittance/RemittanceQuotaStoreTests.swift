@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceQuotaStore = RevenueCycle.newMemoryRemittanceQuotaStore()
        let item = RevenueCycle.newRemittanceQuota("code-292", name: "name-26")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
