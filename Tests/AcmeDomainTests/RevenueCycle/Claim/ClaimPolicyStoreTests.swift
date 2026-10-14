@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimPolicyStore = RevenueCycle.newMemoryClaimPolicyStore()
        let item = RevenueCycle.newClaimPolicy("code-361", name: "name-840")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
