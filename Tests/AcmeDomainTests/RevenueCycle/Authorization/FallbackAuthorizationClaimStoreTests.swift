@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackAuthorizationClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackAuthorizationClaimStore = RevenueCycle.newMemoryFallbackAuthorizationClaimStore()
        let item = RevenueCycle.newFallbackAuthorizationClaim("code-37", title: "title-540")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
