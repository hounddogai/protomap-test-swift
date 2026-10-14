@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveRemittanceGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveRemittanceGroupStore = RevenueCycle.newMemoryAdaptiveRemittanceGroupStore()
        let item = RevenueCycle.newAdaptiveRemittanceGroup("code-788", title: "title-488")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
