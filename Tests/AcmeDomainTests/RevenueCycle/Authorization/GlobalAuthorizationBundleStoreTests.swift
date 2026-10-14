@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalAuthorizationBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalAuthorizationBundleStore = RevenueCycle.newMemoryGlobalAuthorizationBundleStore()
        let item = RevenueCycle.newGlobalAuthorizationBundle("code-33", name: "name-525")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
