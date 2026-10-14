@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualChargeOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualChargeOverrideStore = RevenueCycle.newMemoryManualChargeOverrideStore()
        let item = RevenueCycle.newManualChargeOverride("code-468", name: "name-759")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
