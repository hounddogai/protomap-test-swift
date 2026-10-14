@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictChargeGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictChargeGroupStore = RevenueCycle.newMemoryStrictChargeGroupStore()
        let item = RevenueCycle.newStrictChargeGroup("code-491", title: "title-718")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
