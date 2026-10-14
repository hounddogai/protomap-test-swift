@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimMappingStore = RevenueCycle.newMemoryClaimMappingStore()
        let item = RevenueCycle.newClaimMapping("code-809", name: "name-188")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
