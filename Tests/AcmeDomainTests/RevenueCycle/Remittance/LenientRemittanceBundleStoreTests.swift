@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientRemittanceBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientRemittanceBundleStore = RevenueCycle.newMemoryLenientRemittanceBundleStore()
        let item = RevenueCycle.newLenientRemittanceBundle("code-418", title: "title-784")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
