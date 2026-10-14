@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRegionalRemittanceVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RegionalRemittanceVarianceStore = RevenueCycle.newMemoryRegionalRemittanceVarianceStore()
        let item = RevenueCycle.newRegionalRemittanceVariance("code-285", name: "name-892")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
