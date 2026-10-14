@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimProfileStore = RevenueCycle.newMemoryClaimProfileStore()
        let item = RevenueCycle.newClaimProfile("code-503", name: "name-361")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
