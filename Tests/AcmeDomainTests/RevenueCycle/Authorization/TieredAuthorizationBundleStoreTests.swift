@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredAuthorizationBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredAuthorizationBundleStore = RevenueCycle.newMemoryTieredAuthorizationBundleStore()
        let item = RevenueCycle.newTieredAuthorizationBundle("code-599", title: "title-734")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
