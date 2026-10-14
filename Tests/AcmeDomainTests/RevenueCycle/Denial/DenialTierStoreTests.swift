@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialTierStore = RevenueCycle.newMemoryDenialTierStore()
        let item = RevenueCycle.newDenialTier("code-93", title: "title-581")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
