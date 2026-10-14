@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationPolicyStore = RevenueCycle.newMemoryAuthorizationPolicyStore()
        let item = RevenueCycle.newAuthorizationPolicy("code-637", name: "name-382")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
