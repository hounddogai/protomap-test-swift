@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalClaimBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalClaimBundleStore = RevenueCycle.newMemoryGlobalClaimBundleStore()
        let item = RevenueCycle.newGlobalClaimBundle("code-559", name: "name-975")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
