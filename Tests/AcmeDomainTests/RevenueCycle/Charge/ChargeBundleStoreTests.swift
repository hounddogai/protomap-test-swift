@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeBundleStore = RevenueCycle.newMemoryChargeBundleStore()
        let item = RevenueCycle.newChargeBundle("code-660", title: "title-753")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
