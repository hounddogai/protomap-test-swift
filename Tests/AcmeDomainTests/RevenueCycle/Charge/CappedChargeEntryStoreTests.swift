@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedChargeEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedChargeEntryStore = RevenueCycle.newMemoryCappedChargeEntryStore()
        let item = RevenueCycle.newCappedChargeEntry("code-244", title: "title-972")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
