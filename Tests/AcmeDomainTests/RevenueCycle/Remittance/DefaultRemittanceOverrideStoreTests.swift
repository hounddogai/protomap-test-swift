@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultRemittanceOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultRemittanceOverrideStore = RevenueCycle.newMemoryDefaultRemittanceOverrideStore()
        let item = RevenueCycle.newDefaultRemittanceOverride("code-180", name: "name-753")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
