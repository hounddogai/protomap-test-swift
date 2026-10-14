@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeBatchStore = RevenueCycle.newMemoryChargeBatchStore()
        let item = RevenueCycle.newChargeBatch("code-432", name: "name-223")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
