@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyClaimProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyClaimProfileStore = RevenueCycle.newMemoryLegacyClaimProfileStore()
        let item = RevenueCycle.newLegacyClaimProfile("code-683", name: "name-993")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
