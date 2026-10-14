@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceCycleStore = RevenueCycle.newMemoryRemittanceCycleStore()
        let item = RevenueCycle.newRemittanceCycle("code-940", name: "name-521")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
