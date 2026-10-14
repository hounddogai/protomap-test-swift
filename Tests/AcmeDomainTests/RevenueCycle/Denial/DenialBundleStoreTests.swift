@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialBundleStore = RevenueCycle.newMemoryDenialBundleStore()
        let item = RevenueCycle.newDenialBundle("code-659", name: "name-773")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
