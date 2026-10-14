@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimRollupStore = RevenueCycle.newMemoryClaimRollupStore()
        let item = RevenueCycle.newClaimRollup("code-333", name: "name-337")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
