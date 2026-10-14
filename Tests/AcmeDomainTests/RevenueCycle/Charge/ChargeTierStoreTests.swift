@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeTierStore = RevenueCycle.newMemoryChargeTierStore()
        let item = RevenueCycle.newChargeTier("code-863", name: "name-231")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
