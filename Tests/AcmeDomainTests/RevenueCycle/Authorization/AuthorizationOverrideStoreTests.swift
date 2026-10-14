@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationOverrideStore = RevenueCycle.newMemoryAuthorizationOverrideStore()
        let item = RevenueCycle.newAuthorizationOverride("code-776", title: "title-927")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
