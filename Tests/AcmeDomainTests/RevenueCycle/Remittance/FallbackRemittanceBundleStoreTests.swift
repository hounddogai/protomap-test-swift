@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackRemittanceBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackRemittanceBundleStore = RevenueCycle.newMemoryFallbackRemittanceBundleStore()
        let item = RevenueCycle.newFallbackRemittanceBundle("code-593", label: "label-338")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
