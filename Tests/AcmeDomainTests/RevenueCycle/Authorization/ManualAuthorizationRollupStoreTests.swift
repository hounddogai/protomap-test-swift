@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualAuthorizationRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualAuthorizationRollupStore = RevenueCycle.newMemoryManualAuthorizationRollupStore()
        let item = RevenueCycle.newManualAuthorizationRollup("code-195", label: "label-947")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
