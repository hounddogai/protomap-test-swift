@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualDenialTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualDenialTierStore = RevenueCycle.newMemoryManualDenialTierStore()
        let item = RevenueCycle.newManualDenialTier("code-293", label: "label-759")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
