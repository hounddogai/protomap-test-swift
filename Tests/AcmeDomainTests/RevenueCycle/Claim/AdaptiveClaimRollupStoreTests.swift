@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveClaimRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveClaimRollupStore = RevenueCycle.newMemoryAdaptiveClaimRollupStore()
        let item = RevenueCycle.newAdaptiveClaimRollup("code-634", name: "name-558")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
