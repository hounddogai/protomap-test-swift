@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultDenialCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultDenialCycleStore = RevenueCycle.newMemoryDefaultDenialCycleStore()
        let item = RevenueCycle.newDefaultDenialCycle("code-663", title: "title-806")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
