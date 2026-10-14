@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimOverrideStore = RevenueCycle.newMemoryClaimOverrideStore()
        let item = RevenueCycle.newClaimOverride("code-114", label: "label-974")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
