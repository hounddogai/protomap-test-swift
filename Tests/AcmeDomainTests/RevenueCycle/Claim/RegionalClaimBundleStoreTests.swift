@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRegionalClaimBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RegionalClaimBundleStore = RevenueCycle.newMemoryRegionalClaimBundleStore()
        let item = RevenueCycle.newRegionalClaimBundle("code-163", label: "label-840")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
