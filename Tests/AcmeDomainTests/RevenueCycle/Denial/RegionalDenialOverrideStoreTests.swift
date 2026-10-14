@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRegionalDenialOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RegionalDenialOverrideStore = RevenueCycle.newMemoryRegionalDenialOverrideStore()
        let item = RevenueCycle.newRegionalDenialOverride("code-775", title: "title-700")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
