@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualDenialCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualDenialCycleStore = RevenueCycle.newMemoryManualDenialCycleStore()
        let item = RevenueCycle.newManualDenialCycle("code-956", title: "title-471")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
