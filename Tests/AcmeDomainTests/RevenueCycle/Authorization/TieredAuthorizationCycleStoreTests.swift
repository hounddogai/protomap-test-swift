@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredAuthorizationCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredAuthorizationCycleStore = RevenueCycle.newMemoryTieredAuthorizationCycleStore()
        let item = RevenueCycle.newTieredAuthorizationCycle("code-794", name: "name-376")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
