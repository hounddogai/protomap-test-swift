@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultClaimRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultClaimRollupStore = RevenueCycle.newMemoryDefaultClaimRollupStore()
        let item = RevenueCycle.newDefaultClaimRollup("code-231", name: "name-654")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
