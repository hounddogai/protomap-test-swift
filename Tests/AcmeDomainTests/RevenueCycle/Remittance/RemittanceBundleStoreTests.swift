@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceBundleStore = RevenueCycle.newMemoryRemittanceBundleStore()
        let item = RevenueCycle.newRemittanceBundle("code-196", label: "label-975")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
