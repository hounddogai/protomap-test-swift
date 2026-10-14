@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultClaimBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultClaimBundleStore = RevenueCycle.newMemoryDefaultClaimBundleStore()
        let item = RevenueCycle.newDefaultClaimBundle("code-852", title: "title-115")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
